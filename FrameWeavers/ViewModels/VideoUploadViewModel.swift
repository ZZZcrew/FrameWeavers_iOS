import Foundation
import SwiftUI
import PhotosUI
import AVFoundation
import CoreMedia
import Combine
import SwiftData

typealias PickerItem = PhotosUI.PhotosPickerItem

class VideoUploadViewModel: ObservableObject {
    // MARK: - 状态属性
    @Published var selectedVideos: [URL] = []
    @Published var uploadStatus: UploadStatus = .pending
    @Published var uploadProgress: Double = 0
    @Published var errorMessage: String?
    @Published var comicResult: ComicResultData?
    @Published var isShowingPicker = false
    @Published var baseFrames: [BaseFrameData] = []
    @Published var keyFrames: [KeyFrameData] = []
    @Published var shouldNavigateToStyleSelection = false
    @Published var selectedStyle: String = ""
    
    // MARK: - 服务
    private let videoSelectionVM: VideoSelectionViewModel
    private let videoUploadService: VideoUploadService
    private let baseFrameService: BaseFrameExtractionService
    private let comicGenerationService: ComicGenerationService
    private let taskPollingService: TaskStatusPollingService
    private let progressService: ProgressMonitoringService
    private let historyService: HistoryService?
    
    private var cancellables = Set<AnyCancellable>()
    private var currentTaskId: String?
    private var currentVideoPath: String?
    
    init(
        videoSelectionVM: VideoSelectionViewModel = VideoSelectionViewModel(),
        videoUploadService: VideoUploadService = VideoUploadService(),
        baseFrameService: BaseFrameExtractionService = BaseFrameExtractionService(),
        comicGenerationService: ComicGenerationService = ComicGenerationService(),
        taskPollingService: TaskStatusPollingService = TaskStatusPollingService(),
        progressService: ProgressMonitoringService = ProgressMonitoringService(expectedDuration: 300)
    ) {
        self.videoSelectionVM = videoSelectionVM
        self.videoUploadService = videoUploadService
        self.baseFrameService = baseFrameService
        self.comicGenerationService = comicGenerationService
        self.taskPollingService = taskPollingService
        self.progressService = progressService
        self.historyService = nil
        
        setupBindings()
    }
    
    private func setupBindings() {
        // 视频选择状态绑定
        videoSelectionVM.$selectedVideos.assign(to: &$selectedVideos)
        videoSelectionVM.$uploadStatus.assign(to: &$uploadStatus)
        videoSelectionVM.$errorMessage.assign(to: &$errorMessage)
        videoSelectionVM.$isShowingPicker.assign(to: &$isShowingPicker)
        
        // 进度监控
        progressService.progressPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$uploadProgress)
            .store(in: &cancellables)
    }
    
    // MARK: - 公共接口
    func setHistoryService(modelContext: ModelContext) {
        self.historyService = HistoryService(modelContext: modelContext)
    }
    
    func selectStyle(_ style: String) {
        selectedStyle = style
    }
    
    func startGeneration() async -> Bool {
        guard !selectedStyle.isEmpty else {
            errorMessage = "请选择故事风格"
            return false
        }
        
        guard !selectedVideos.isEmpty else {
            errorMessage = "请先选择视频"
            return false
        }
        
        return await performUploadAndGeneration()
    }
    
    func processSelectedItems(items: [PickerItem]) async -> [URL] {
        return await videoSelectionVM.processSelectedItems(items)
    }
    
    func validateVideos() {
        videoSelectionVM.validateVideos()
    }
    
    // MARK: - 内部实现
    private func performUploadAndGeneration() async -> Bool {
        do {
            errorMessage = nil
            uploadStatus = .uploading
            
            let expectedDuration = UploadTimingCalculator.calculateExpectedDuration(for: selectedVideos)
            progressService.startMonitoring()
            
            let uploadResponse = try await videoUploadService.uploadVideos(videoURLs: selectedVideos) { [weak self] progress in
                DispatchQueue.main.async {
                    self?.uploadProgress = progress
                }
            }
            
            guard let taskId = uploadResponse.task_id else {
                throw VideoUploadService.VideoUploadError.serverError("No task ID received")
            }
            
            currentTaskId = taskId
            currentVideoPath = uploadResponse.video_path
            
            uploadStatus = .processing
            
            // 开始任务状态轮询
            await monitorTaskStatus(taskId: taskId)
            
            return true
            
        } catch {
            await handleError(error)
            return false
        }
    }
    
    private func monitorTaskStatus(taskId: String) async {
        let maxWaitTime: TimeInterval = 3000.0
        let startTime = Date()
        var lastProgress = -1
        
        while Date().timeIntervalSince(startTime) < maxWaitTime {
            do {
                let status = try await taskPollingService.getCurrentStatus(taskId: taskId)
                
                await handleTaskStatusUpdate(status)
                
                if status.isCompleted {
                    await fetchAndSetComicResult(taskId: taskId)
                    return
                } else if status.isFailed {
                    throw PollingError.serverError(status.message ?? "任务失败")
                }
                
                // 每隔2秒查询一次
                try await Task.sleep(nanoseconds: 2_000_000_000)
                
            } catch {
                await handleError(error)
                return
            }
        }
        
        await MainActor.run {
            uploadStatus = .failed
            errorMessage = "连环画生成监控超时，请稍后重试"
        }
    }
    
    private func handleTaskStatusUpdate(_ status: TaskStatus) async {
        await MainActor.run {
            if let progress = status.progress {
                uploadProgress = Double(progress) / 100.0
            }
            
            // 可以提前尝试提取基础帧
            if status.isProcessing && baseFrames.isEmpty {
                Task {
                    await tryEarlyBaseFrameExtraction()
                }
            }
        }
    }
    
    private func tryEarlyBaseFrameExtraction() async {
        guard let taskId = currentTaskId else { return }
        
        do {
            if let response = await baseFrameService.extractBaseFramesEarly(taskId: taskId, interval: 1.0) {
                await MainActor.run {
                    self.baseFrames = response.results.flatMap { result in
                        result.baseFramesPaths.enumerated().map { index, path in
                            BaseFrameData(
                                framePath: path,
                                frameIndex: index,
                                timestamp: Double(index) * 1.0
                            )
                        }
                    }
                }
            }
        } catch {
            // 提前提取失败是正常的，可以忽略
            print("提前提取基础帧失败: \(error)")
        }
    }
    
    private func fetchAndSetComicResult(taskId: String) async {
        do {
            let response = try await comicGenerationService.fetchComicResult(taskId: taskId)
            
            if let comicResult = comicGenerationService.convertToComicResult(from: response, taskId: taskId) {
                await MainActor.run {
                    self.comicResult = comicResult
                    self.uploadStatus = .completed
                    self.uploadProgress = 1.0
                    self.saveToHistory(comicResult)
                }
            } else {
                throw PollingError.comicGenerationFailed
            }
            
        } catch {
            await handleError(error)
        }
    }
    
    // MARK: - 辅助方法
    private func saveToHistory(_ comicResult: ComicResultData) {
        guard let historyService = historyService else {
            print("⚠️ 历史记录服务未初始化")
            return
        }
        
        let success = historyService.saveToHistory(comicResult)
        if success {
            print("✅ 画册已保存: \(comicResult.title)")
        }
    }
    
    private func handleError(_ error: Error) async {
        await MainActor.run {
            uploadStatus = .failed
            errorMessage = self.localizedErrorDescription(error)
            
            progressService.stopMonitoring()
            taskPollingService.stopPolling()
        }
    }
    
    private func localizedErrorDescription(_ error: Error) -> String {
        if let uploadError = error as? VideoUploadService.VideoUploadError {
            return uploadError.errorDescription ?? "上传失败"
        } else if let pollingError = error as? PollingError {
            return pollingError.errorDescription ?? "处理失败"
        } else {
            return error.localizedDescription
        }
    }
    
    // MARK: - 操作控制
    func cancelUpload() {
        videoUploadService.cancelCurrentUpload()
        taskPollingService.stopPolling()
        progressService.stopMonitoring()
        
        if let taskId = currentTaskId {
            cancelBackendTask(taskId: taskId)
        }
        
        reset()
    }
    
    func reset() {
        selectedVideos = []
        uploadStatus = .pending
        uploadProgress = 0
        errorMessage = nil
        comicResult = nil
        baseFrames = []
        keyFrames = []
        shouldNavigateToStyleSelection = false
        selectedStyle = ""
        currentTaskId = nil
        currentVideoPath = nil
        
        videoSelectionVM.resetSelection()
        taskPollingService.stopPolling()
        progressService.stopMonitoring()
    }
    
    func resetNavigationState() {
        shouldNavigateToStyleSelection = false
        selectedStyle = ""
    }
    
    private func cancelBackendTask(taskId: String) {
        Task {
            do {
                let endpoint = NetworkConfig.Endpoint.taskCancel(taskId: taskId)
                var request = URLRequest(url: endpoint.url)
                request.httpMethod = endpoint.method
                
                _ = try await networkService.request(request)
                print("任务取消请求已发送")
            } catch {
                print("取消任务失败: \(error)")
            }
        }
    }
}

// MARK: - 辅助枚举和模型
enum UploadStatus: String {
    case pending = "待处理"
    case uploading = "上传中"
    case processing = "处理中"
    case completed = "已完成"
    case failed = "失败"
}

enum PollingError: Error {
    case serverError(String)
    case networkError(String)
    case comicGenerationFailed
    
    var errorDescription: String? {
        switch self {
        case .serverError(let message): return message
        case .networkError(let message): return "网络错误: \(message)"
        case .comicGenerationFailed: return "连环画生成失败"
        }
    }
}