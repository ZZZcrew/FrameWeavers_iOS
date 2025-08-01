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
    private var progressTimer: Timer?   // 进度查询定时器
    private let baseFrameService = BaseFrameService() // 基础帧服务
    private let comicGenerationService = ComicGenerationService() // 连环画生成服务
    private var historyService: HistoryService? // 历史记录服务

    // MARK: - 视频选择ViewModel（依赖注入）
    var videoSelectionViewModel = VideoSelectionViewModel()

    // MARK: - 视频上传服务（依赖注入）
    private let videoUploadService = VideoUploadService()

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

    // 视频验证功能已移至VideoSelectionViewModel
    
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

    // 网络上传相关功能已移至VideoUploadService

    // HTTP上传功能已移至VideoUploadService

    // MIME类型处理已移至VideoUploadService

    // 上传响应处理已移至VideoUploadService
    
    // MARK: - 进度轮询
    private func startProgressPolling(taskId: String) {
        progressTimer?.invalidate()

        progressTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkTaskStatus(taskId: taskId)
        }
    }

    private func checkTaskStatus(taskId: String) {
        let url = NetworkConfig.Endpoint.taskStatus(taskId: taskId).url

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.handleTaskStatusResponse(data: data, response: response, error: error)
            }
        }.resume()
    }

    private func handleTaskStatusResponse(data: Data?, response: URLResponse?, error: Error?) {
        guard let data = data,
              let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return
        }

        // 打印响应内容以便调试
        if let responseString = String(data: data, encoding: .utf8) {
            print("任务状态响应: \(responseString)")
        }

        do {
            // 尝试解析为通用JSON对象
            if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // 提取关键字段
                let _ = jsonObject["success"] as? Bool ?? false
                let status = jsonObject["status"] as? String ?? ""
                let progress = jsonObject["progress"] as? Int ?? 0
                let message = jsonObject["message"] as? String ?? ""

                // 更新进度
                uploadProgress = Double(progress) / 100.0

                print("任务状态: \(status), 进度: \(progress)%")

                if status == "completed" {
                    uploadStatus = .processing // 先设置为处理中
                    progressTimer?.invalidate()
                    progressTimer = nil
                    // 开始提取基础帧
                    Task {
                        await extractBaseFrames()
                    }
                } else if status == "processing" || status == "uploaded" {
                    // 视频正在处理中，可以尝试提前提取基础帧
                    uploadStatus = .processing
                    // 如果还没有基础帧数据，尝试提取
                    if baseFrames.isEmpty {
                        Task {
                            await tryEarlyBaseFrameExtraction()
                        }
                    }
                } else if status == "error" || status == "cancelled" {
                    uploadStatus = .failed
                    errorMessage = message
                    progressTimer?.invalidate()
                    progressTimer = nil
                } else {
                    // 处理中或上传完成等待处理
                    uploadStatus = .processing
                }
            }
        } catch {
            print("解析状态响应失败: \(error)")
        }
    }

    private func simulateProcessing() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.comicResult = self.createMockComicResult()
            self.uploadStatus = .completed
        }
    }

    // MARK: - 基础帧提取

    /// 尝试提前提取基础帧（在视频还在处理时）
    private func tryEarlyBaseFrameExtraction() async {
        guard let taskId = currentTaskId else { return }

        print("🚀 尝试提前提取基础帧, taskId: \(taskId)")

        do {
            // 尝试提取基础帧，如果后端还没准备好会返回错误，我们忽略错误继续等待
            let response = try await baseFrameService.extractBaseFrames(taskId: taskId, interval: 1.0)

            if response.success && !response.results.isEmpty {
                print("🎉 提前获取到基础帧数据！")

                // 转换响应数据为BaseFrameData
                let frames = response.results.flatMap { result in
                    print("🎞️ 视频: \(result.videoName), 基础帧数量: \(result.baseFramesCount)")
                    return result.baseFramesPaths.enumerated().map { index, path in
                        BaseFrameData(
                            framePath: path,
                            frameIndex: index,
                            timestamp: Double(index) * 1.0
                        )
                    }
                }

                await MainActor.run {
                    self.baseFrames = frames
                    print("✅ 提前设置基础帧数据成功，数量: \(frames.count)")
                }
            }
        } catch {
            // 提前提取失败是正常的，不需要报错，继续等待正常流程
            print("ℹ️ 提前提取基础帧失败（正常情况）: \(error.localizedDescription)")
        }
    }

    private func extractBaseFrames() async {
        guard let taskId = currentTaskId else {
            print("❌ 基础帧提取失败: 缺少任务ID")
            await MainActor.run {
                self.uploadStatus = .failed
                self.errorMessage = "缺少任务ID"
            }
            return
        }

        // 如果已经有基础帧数据，跳过提取直接进入下一步
        if !baseFrames.isEmpty {
            print("ℹ️ 基础帧数据已存在，跳过提取步骤")
            await generateCompleteComic()
            return
        }

        print("🎬 开始提取基础帧, taskId: \(taskId)")

        do {
            let response = try await baseFrameService.extractBaseFrames(taskId: taskId, interval: 1.0)
            print("✅ 基础帧提取API调用成功")
            print("📊 响应数据: success=\(response.success), message=\(response.message)")
            print("📁 结果数量: \(response.results.count)")

            // 转换响应数据为BaseFrameData
            let frames = response.results.flatMap { result in
                print("🎞️ 视频: \(result.videoName), 基础帧数量: \(result.baseFramesCount)")
                print("📸 基础帧路径: \(result.baseFramesPaths)")
                return result.baseFramesPaths.enumerated().map { index, path in
                    BaseFrameData(
                        framePath: path,
                        frameIndex: index,
                        timestamp: Double(index) * 1.0
                    )
                }
            }

            print("🖼️ 转换后的基础帧数量: \(frames.count)")

            await MainActor.run {
                self.baseFrames = frames
                print("✅ 基础帧数据已设置到ViewModel")
            }

            // 开始生成完整连环画
            await generateCompleteComic()

        } catch {
            print("❌ 基础帧提取失败: \(error)")
            await MainActor.run {
                self.uploadStatus = .failed
                self.errorMessage = "基础帧提取失败: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - 生成完整连环画
    private func generateCompleteComic() async {
        guard let taskId = currentTaskId else {
            print("❌ 没有有效的任务ID")
            await MainActor.run {
                self.uploadStatus = .failed
                self.errorMessage = "没有有效的任务ID"
            }
            return
        }

        guard let videoPath = currentVideoPath else {
            print("❌ 没有有效的视频路径")
            await MainActor.run {
                self.uploadStatus = .failed
                self.errorMessage = "没有有效的视频路径"
            }
            return
        }

        print("🎬 开始生成完整连环画，任务ID: \(taskId)")
        print("📹 使用视频路径: \(videoPath)")

        // 使用合理的默认关键帧数量，参考API文档默认值
        // 注意：targetFrames是告诉AI我们希望选出多少个关键帧，不是基础帧数量
        // 基础帧是从视频中按时间间隔提取的所有帧（可能几十帧）
        // 关键帧是AI分析后选出的重要帧（通常8-12帧），最终成为连环画的页数
        let targetFrames = 8  // API文档中的默认值，让AI从基础帧中选出8个关键帧
        print("🎯 使用目标关键帧数: \(targetFrames) (基础帧数量: \(baseFrames.count))")

        do {
            // 创建请求参数，严格参考Python测试文件
            let request = CompleteComicRequest(
                taskId: taskId,
                videoPath: videoPath,  // 必须：使用后端返回的视频路径
                storyStyle: "温馨童话",  // 必须：故事风格关键词
                targetFrames: targetFrames,  // 动态使用后端返回的帧数
                frameInterval: 2.0,  // 参考Python测试
                significanceWeight: 0.7,  // 参考Python测试
                qualityWeight: 0.3,  // 参考Python测试
                stylePrompt: "Convert to Ink and brushwork style, Chinese style, Yellowed and old, Low saturation, Low brightness",  // 参考Python测试
                imageSize: "1780x1024",  // 参考Python测试
                maxConcurrent: 50
            )

            // 启动连环画生成
            let response = try await comicGenerationService.startCompleteComicGeneration(request: request)
            print("✅ 连环画生成已启动: \(response.message)")

            await MainActor.run {
                self.uploadStatus = .processing
            }

            // 开始轮询任务状态，等待完成
            await pollComicGenerationStatus(taskId: taskId)

        } catch {
            print("❌ 连环画生成失败: \(error)")
            await MainActor.run {
                self.uploadStatus = .failed
                self.errorMessage = "连环画生成失败: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - 轮询连环画生成状态
    private func pollComicGenerationStatus(taskId: String) async {
        let maxWaitTime: TimeInterval = 3000.0  // 最多等待3000秒（50分钟）
        let interval: TimeInterval = 2.0  // 每2秒查询一次，参考Python实现
        let startTime = Date()
        var lastProgress = -1
        var consecutiveErrors = 0  // 连续错误计数
        let maxConsecutiveErrors = 10  // 最多允许10次连续错误

        // 阶段描述映射，参考Python实现
        let stageDescriptions = [
            "initializing": "初始化中",
            "extracting_keyframes": "正在提取关键帧",
            "generating_story": "正在生成故事",
            "stylizing_frames": "正在风格化处理",
            "completed": "已完成"
        ]

        while Date().timeIntervalSince(startTime) < maxWaitTime {
            do {
                // 查询任务状态
                let statusUrl = NetworkConfig.Endpoint.taskStatus(taskId: taskId).url
                let (data, response) = try await URLSession.shared.data(from: statusUrl)

                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                    consecutiveErrors += 1
                    print("❌ 状态查询失败，HTTP状态码: \(statusCode)，连续错误: \(consecutiveErrors)")

                    // 打印错误响应内容以便调试
                    if let errorString = String(data: data, encoding: .utf8) {
                        print("📄 错误响应内容: \(errorString)")
                    }

                    // 如果连续错误太多，或者是400错误且进度已经较高，尝试获取最终结果
                    if consecutiveErrors >= maxConsecutiveErrors ||
                       (statusCode == 400 && lastProgress >= 70) {
                        print("⚠️ 连续错误过多或高进度400错误，尝试获取最终结果")
                        await fetchComicResult(taskId: taskId)
                        return
                    }

                    do {
                        try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                    } catch {
                        print("⚠️ 等待间隔失败: \(error)")
                    }
                    continue
                }

                let statusResponse = try JSONDecoder().decode(TaskStatusResponse.self, from: data)

                // 成功获取状态，重置错误计数
                consecutiveErrors = 0

                // 只在进度变化时打印，参考Python实现
                if statusResponse.progress != lastProgress {
                    let stage = statusResponse.stage ?? "unknown"
                    let stageDesc = stageDescriptions[stage] ?? stage
                    print("📈 \(statusResponse.progress)% - \(stageDesc)")
                    lastProgress = statusResponse.progress

                    await MainActor.run {
                        self.uploadProgress = Double(statusResponse.progress) / 100.0
                    }
                }

                // 检查完成状态，参考Python实现
                if statusResponse.status == "complete_comic_completed" {
                    print("✅ 连环画生成完成！")
                    await fetchComicResult(taskId: taskId)
                    return
                } else if statusResponse.status == "complete_comic_failed" || statusResponse.status == "error" {
                    print("❌ 连环画生成失败: \(statusResponse.message)")
                    await MainActor.run {
                        self.uploadStatus = .failed
                        self.errorMessage = "连环画生成失败: \(statusResponse.message)"
                    }
                    return
                }

                // 等待下次查询
                do {
                    try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                } catch {
                    print("⚠️ 等待间隔失败: \(error)")
                    // 如果sleep失败，继续循环
                }

            } catch {
                print("⚠️ 查询状态异常: \(error)")
                // 继续尝试，参考Python实现
                do {
                    try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                } catch {
                    print("⚠️ 等待间隔失败: \(error)")
                    // 如果连sleep都失败了，直接跳出循环
                    break
                }
            }
        }

        // 超时处理
        print("⏰ 连环画生成监控超时（3000秒）")
        await MainActor.run {
            self.uploadStatus = .failed
            self.errorMessage = "连环画生成监控超时，请稍后重试"
        }
    }

    // MARK: - 获取连环画结果
    private func fetchComicResult(taskId: String) async {
        do {
            print("📖 获取连环画结果...")
            let resultResponse = try await comicGenerationService.getComicResult(taskId: taskId)

            if let comicResult = comicGenerationService.convertToComicResult(from: resultResponse, taskId: taskId) {
                print("✅ 连环画结果转换成功，共\(comicResult.panels.count)页")

                await MainActor.run {
                    self.comicResult = comicResult
                    self.uploadStatus = .completed
                    self.uploadProgress = 1.0

                    // 保存到历史记录
                    self.saveToHistory(comicResult)
                }
            } else {
                print("❌ 连环画结果转换失败")
                await MainActor.run {
                    self.uploadStatus = .failed
                    self.errorMessage = "连环画结果转换失败"
                }
            }

        } catch {
            print("❌ 获取连环画结果失败: \(error)")
            await MainActor.run {
                self.uploadStatus = .failed
                self.errorMessage = "获取连环画结果失败: \(error.localizedDescription)"
            }
        }
    }

    private func createMockComicResult() -> ComicResult {
        let videoTitle = videoSelectionViewModel.selectedVideos.isEmpty ? "测试视频.mp4" : videoSelectionViewModel.selectedVideos.map { $0.lastPathComponent }.joined(separator: ", ")

        return ComicResult(
            comicId: "mock-comic-123",
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "mock-device",
            title: "海滩上的温暖时光",  // 添加故事标题
            originalVideoTitle: videoTitle,
            creationDate: ISO8601DateFormatter().string(from: Date()),
            panelCount: 4,
            panels: [
                ComicPanel(panelNumber: 1, imageUrl: "Image1", narration: "故事从宁静的沙滩开始"),
                ComicPanel(panelNumber: 2, imageUrl: "Image2", narration: "一个小小身影闯入画面"),
                ComicPanel(panelNumber: 3, imageUrl: "Image3", narration: "阳光洒在海面上"),
                ComicPanel(panelNumber: 4, imageUrl: "Image4", narration: "一家人的笑声比阳光还灿烂")
            ],
            finalQuestions: [
                "你还记得那天沙子的温度吗？",
                "视频里谁的笑声最大？",
                "用一个词形容那天的天空？"
            ]
        )
    }
    
    // 上传模式切换方法已删除

    func cancelUpload() {
        // 取消上传服务
        videoUploadService.cancelUpload()

        // 停止进度轮询
        progressTimer?.invalidate()
        progressTimer = nil

        // 如果有任务ID，尝试取消后端任务
        if let taskId = currentTaskId {
            cancelBackendTask(taskId: taskId)
        }

        cancellables.removeAll()
        uploadStatus = .pending
        uploadProgress = 0
        errorMessage = nil
        currentTaskId = nil
    }

    private func cancelBackendTask(taskId: String) {
        let url = NetworkConfig.Endpoint.taskCancel(taskId: taskId).url
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data,
               let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                do {
                    let cancelResponse = try JSONDecoder().decode(TaskCancelResponse.self, from: data)
                    print("任务取消结果: \(cancelResponse.message)")
                } catch {
                    print("解析取消响应失败: \(error)")
                }
            }
        }.resume()
    }

    func reset() {
        // 重置视频选择ViewModel
        videoSelectionViewModel.clearAllVideos()

        // 重置上传服务
        videoUploadService.cancelUpload()

        uploadStatus = .pending
        uploadProgress = 0
        errorMessage = nil
        comicResult = nil
        cancellables.removeAll()
        progressTimer?.invalidate()
        progressTimer = nil
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

    /// 保存画册到历史记录
    /// - Parameter comicResult: 要保存的画册结果
    private func saveToHistory(_ comicResult: ComicResult) {
        guard let historyService = historyService else {
            print("⚠️ 历史记录服务未初始化，无法保存历史记录")
            return
        }

        let success = historyService.saveToHistory(comicResult)
        if success {
            print("✅ 画册已成功保存到历史记录: \(comicResult.title)")
        } else {
            print("❌ 保存画册到历史记录失败")
        }
    }
}
