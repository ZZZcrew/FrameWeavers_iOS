import Foundation
import SwiftUI
import PhotosUI
import AVFoundation
import CoreMedia
import Combine
import SwiftData

// 类型别名解决编译问题
typealias PickerItem = PhotosUI.PhotosPickerItem

class VideoUploadViewModel: ObservableObject {
    // MARK: - UI状态属性
    @Published var uploadStatus: UploadStatus = .pending
    @Published var uploadProgress: Double = 0
    @Published var errorMessage: String?
    @Published var comicResult: ComicResult?
    @Published var baseFrames: [BaseFrameData] = [] // 基础帧数据
    @Published var keyFrames: [KeyFrameData] = [] // 关键帧数据
    @Published var shouldNavigateToStyleSelection = false // 导航状态
    @Published var selectedStyle: String = "" // 选择的故事风格

    // MARK: - 服务依赖
    private var cancellables = Set<AnyCancellable>()
    private var currentTaskId: String?  // 当前任务ID
    private var currentVideoPath: String?  // 当前视频路径
    private var historyService: HistoryService? // 历史记录服务

    // MARK: - 视频选择ViewModel（依赖注入）
    var videoSelectionViewModel = VideoSelectionViewModel()

    // MARK: - 视频上传服务（依赖注入）
    private let videoUploadService = VideoUploadService()

    // MARK: - 进度轮询服务（依赖注入）
    private let progressPollingService = ProgressPollingService()

    // MARK: - 连环画生成协调器（依赖注入）
    private let comicGenerationCoordinator = ComicGenerationCoordinator()

    // MARK: - 初始化和配置

    /// 设置历史记录服务
    /// - Parameter modelContext: SwiftData模型上下文
    func setHistoryService(modelContext: ModelContext) {
        self.historyService = HistoryService(modelContext: modelContext)
    }

    // MARK: - 兼容性属性和方法

    /// 兼容性属性，返回第一个选中的视频
    var selectedVideo: URL? {
        return videoSelectionViewModel.selectedVideo
    }

    /// 获取选择的视频列表
    var selectedVideos: [URL] {
        return videoSelectionViewModel.selectedVideos
    }

    /// 选择单个视频（委托给VideoSelectionViewModel）
    func selectVideo(_ url: URL) {
        videoSelectionViewModel.selectVideo(url)
        // 选择视频后自动触发导航
        if !videoSelectionViewModel.selectedVideos.isEmpty {
            shouldNavigateToStyleSelection = true
        }
    }

    /// 选择多个视频（委托给VideoSelectionViewModel）
    func selectVideos(_ urls: [URL]) {
        videoSelectionViewModel.selectVideos(urls)
        // 选择视频后自动触发导航
        if !urls.isEmpty {
            shouldNavigateToStyleSelection = true
        }
    }

    /// 添加视频（委托给VideoSelectionViewModel）
    func addVideo(_ url: URL) {
        videoSelectionViewModel.addVideo(url)
    }

    /// 移除视频（委托给VideoSelectionViewModel）
    func removeVideo(at index: Int) {
        videoSelectionViewModel.removeVideo(at: index)
    }

    /// 处理PhotosPicker选择的视频项目（委托给VideoSelectionViewModel）
    func processSelectedItems(_ items: [PickerItem]) async -> [URL] {
        return await videoSelectionViewModel.processSelectedItems(items)
    }

    /// 选择故事风格
    /// - Parameter style: 故事风格
    func selectStyle(_ style: String) {
        selectedStyle = style
    }

    /// 开始生成连环画
    /// - Returns: 是否成功开始生成
    func startGeneration() -> Bool {
        guard !selectedStyle.isEmpty else {
            print("❌ 故事风格不能为空")
            return false
        }

        guard !videoSelectionViewModel.selectedVideos.isEmpty else {
            print("❌ 没有选择视频")
            errorMessage = "请先选择视频"
            return false
        }

        print("✅ 开始生成连环画")
        print("📊 故事风格: \(selectedStyle)")
        print("📊 当前状态: \(uploadStatus.rawValue)")
        print("📊 视频数量: \(videoSelectionViewModel.selectedVideos.count)")

        // 重置状态
        uploadStatus = .pending
        uploadProgress = 0
        errorMessage = nil

        // 触发上传和处理流程
        uploadVideo()

        return true
    }

    /// 兼容性方法，保持向后兼容
    /// - Parameter style: 选择的故事风格
    /// - Returns: 是否成功开始生成
    func startGeneration(with style: String) -> Bool {
        selectStyle(style)
        return startGeneration()
    }

    func uploadVideo() {
        guard !videoSelectionViewModel.selectedVideos.isEmpty else { return }

        uploadStatus = .uploading
        uploadProgress = 0
        errorMessage = nil

        // 使用VideoUploadService进行上传
        videoUploadService.uploadVideos(videoSelectionViewModel.selectedVideos)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        self?.uploadStatus = .failed
                        self?.errorMessage = error.localizedDescription
                        print("❌ 上传失败: \(error)")
                    }
                },
                receiveValue: { [weak self] result in
                    if result.success, let taskId = result.taskId {
                        print("✅ 上传成功，任务ID: \(taskId)")
                        print("📊 上传文件数: \(result.uploadedFiles ?? 0)")
                        if let invalidFiles = result.invalidFiles, !invalidFiles.isEmpty {
                            print("⚠️ 无效文件: \(invalidFiles)")
                        }

                        // 保存任务信息
                        self?.currentTaskId = taskId
                        self?.currentVideoPath = result.videoPath
                        if let videoPath = result.videoPath {
                            print("📹 保存视频路径: \(videoPath)")
                        }

                        // 更新状态并开始轮询
                        self?.uploadStatus = .processing
                        self?.startProgressPolling(taskId: taskId)
                    } else {
                        self?.uploadStatus = .failed
                        self?.errorMessage = result.message
                    }
                }
            )
            .store(in: &cancellables)
    }


    
    // MARK: - 进度轮询（使用ProgressPollingService）
    private func startProgressPolling(taskId: String) {
        progressPollingService.startProgressPolling(
            taskId: taskId,
            onProgress: { [weak self] result in
                // 更新进度
                self?.uploadProgress = Double(result.progress) / 100.0

                // 根据结果决定是否需要提前提取基础帧
                if result.shouldTryEarlyExtraction && self?.baseFrames.isEmpty == true {
                    Task {
                        await self?.tryEarlyBaseFrameExtraction()
                    }
                }
            },
            onCompleted: { [weak self] in
                // 开始提取基础帧
                Task {
                    await self?.extractBaseFrames()
                }
            },
            onFailed: { [weak self] message in
                self?.uploadStatus = .failed
                self?.errorMessage = message
            }
        )
    }

    // MARK: - 基础帧提取

    /// 尝试提前提取基础帧（在视频还在处理时）
    private func tryEarlyBaseFrameExtraction() async {
        guard let taskId = currentTaskId else {
            print("❌ 没有有效的任务ID用于提前提取")
            return
        }

        let frames = await comicGenerationCoordinator.tryEarlyBaseFrameExtraction(taskId: taskId)

        if !frames.isEmpty {
            await MainActor.run {
                self.baseFrames = frames
            }
        }
    }

    private func extractBaseFrames() async {
        guard let taskId = currentTaskId,
              let videoPath = currentVideoPath else {
            print("❌ 没有有效的任务ID或视频路径")
            await MainActor.run {
                self.uploadStatus = .failed
                self.errorMessage = "没有有效的任务ID或视频路径"
            }
            return
        }

        print("🎬 开始完整连环画生成流程...")

        // 创建生成配置
        let config = ComicGenerationCoordinator.GenerationConfig(
            taskId: taskId,
            videoPath: videoPath,
            storyStyle: selectedStyle.isEmpty ? "温馨童话" : selectedStyle
        )

        // 开始完整生成流程
        await comicGenerationCoordinator.startCompleteGeneration(
            config: config,
            onBaseFramesExtracted: { [weak self] frames in
                Task { @MainActor in
                    self?.baseFrames = frames
                    print("✅ 基础帧提取完成，数量: \(frames.count)")
                }
            },
            onProgressUpdate: { [weak self] progress, message in
                Task { @MainActor in
                    self?.uploadProgress = progress
                    print("📈 进度更新: \(Int(progress * 100))% - \(message)")
                }
            },
            onCompleted: { [weak self] comicResult in
                Task { @MainActor in
                    self?.comicResult = comicResult
                    self?.uploadStatus = .completed
                    self?.uploadProgress = 1.0

                    // 保存到历史记录
                    self?.saveComicToHistory(comicResult)

                    print("✅ 连环画生成完成！")
                }
            },
            onFailed: { [weak self] message in
                Task { @MainActor in
                    self?.uploadStatus = .failed
                    self?.errorMessage = message
                    print("❌ 连环画生成失败: \(message)")
                }
            }
        )
    }

    func cancelUpload() {
        // 取消上传服务
        videoUploadService.cancelUpload()

        // 停止进度轮询
        progressPollingService.stopProgressPolling()

        // 如果有任务ID，尝试取消后端任务
        if let taskId = currentTaskId {
            progressPollingService.cancelBackendTask(taskId: taskId)
        }

        cancellables.removeAll()
        uploadStatus = .pending
        uploadProgress = 0
        errorMessage = nil
        currentTaskId = nil
    }

    func reset() {
        // 重置视频选择ViewModel
        videoSelectionViewModel.clearAllVideos()

        // 重置上传服务
        videoUploadService.cancelUpload()

        // 重置进度轮询服务
        progressPollingService.reset()

        // 重置连环画生成协调器
        comicGenerationCoordinator.reset()

        uploadStatus = .pending
        uploadProgress = 0
        errorMessage = nil
        comicResult = nil
        cancellables.removeAll()
        currentTaskId = nil
        currentVideoPath = nil  // 清理视频路径
        shouldNavigateToStyleSelection = false  // 重置导航状态
        selectedStyle = ""  // 重置选择的风格
    }

    /// 重置导航状态
    func resetNavigationState() {
        shouldNavigateToStyleSelection = false
        selectedStyle = ""
    }

    // MARK: - 历史记录管理

    /// 保存连环画到历史记录
    /// - Parameter comicResult: 要保存的连环画结果
    private func saveComicToHistory(_ comicResult: ComicResult) {
        guard let historyService = historyService else {
            print("⚠️ 历史记录服务未初始化，无法保存历史记录")
            return
        }

        // 异步保存，避免阻塞主线程
        historyService.saveComicToHistory(comicResult) { success in
            // 回调已经在主线程执行，无需额外调度
            if !success {
                print("❌ 保存连环画到历史记录失败")
            }
        }
    }

    /// 获取历史记录摘要
    /// - Returns: 历史记录摘要信息
    func getHistorySummary() -> HistorySummary? {
        return historyService?.getHistorySummary()
    }

    /// 检查连环画是否已存在
    /// - Parameter comicId: 连环画ID
    /// - Returns: 是否已存在
    func isComicAlreadyExists(_ comicId: String) -> Bool {
        return historyService?.isComicAlreadyExists(comicId) ?? false
    }
}
