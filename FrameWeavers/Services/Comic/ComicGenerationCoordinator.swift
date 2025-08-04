import Foundation
import Combine

// MARK: - 连环画生成协调器
/// 负责协调整个连环画生成流程，包括基础帧提取、连环画生成、结果获取等
@Observable
class ComicGenerationCoordinator {
    
    // MARK: - Published Properties
    var generationStatus: ComicGenerationStatus = .idle
    var generationProgress: Double = 0
    var errorMessage: String?
    var comicResult: ComicResult?
    
    // MARK: - Private Properties
    private let comicGenerationService: ComicGenerationService
    private let baseFrameService: BaseFrameService
    private let progressPollingService: ProgressPollingService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Generation Configuration
    struct GenerationConfig {
        let taskId: String
        let videoPath: String
        let storyStyle: String
        let targetFrames: Int
        let frameInterval: Double
        let significanceWeight: Double
        let qualityWeight: Double
        let stylePrompt: String
        let imageSize: String
        let maxConcurrent: Int
        
        init(taskId: String,
             videoPath: String,
             storyStyle: String,
             targetFrames: Int = 8,
             frameInterval: Double = 2.0,
             significanceWeight: Double = 0.7,
             qualityWeight: Double = 0.3,
             stylePrompt: String = "Convert to Ink and brushwork style, Chinese style, Yellowed and old, Low saturation, Low brightness",
             imageSize: String = "1780x1024",
             maxConcurrent: Int = 50) {
            self.taskId = taskId
            self.videoPath = videoPath
            self.storyStyle = storyStyle
            self.targetFrames = targetFrames
            self.frameInterval = frameInterval
            self.significanceWeight = significanceWeight
            self.qualityWeight = qualityWeight
            self.stylePrompt = stylePrompt
            self.imageSize = imageSize
            self.maxConcurrent = maxConcurrent
        }
    }
    
    // MARK: - Generation Result
    struct GenerationResult {
        let success: Bool
        let comicResult: ComicResult?
        let errorMessage: String?
        let baseFrames: [BaseFrameData]
    }
    
    // MARK: - Initialization
    init(comicGenerationService: ComicGenerationService = ComicGenerationService(),
         baseFrameService: BaseFrameService = BaseFrameService(),
         progressPollingService: ProgressPollingService = ProgressPollingService()) {
        self.comicGenerationService = comicGenerationService
        self.baseFrameService = baseFrameService
        self.progressPollingService = progressPollingService
    }
    
    // MARK: - 完整连环画生成流程
    
    /// 开始完整的连环画生成流程
    /// - Parameters:
    ///   - config: 生成配置
    ///   - onBaseFramesExtracted: 基础帧提取完成回调
    ///   - onProgressUpdate: 进度更新回调
    ///   - onCompleted: 完成回调
    ///   - onFailed: 失败回调
    func startCompleteGeneration(
        config: GenerationConfig,
        onBaseFramesExtracted: @escaping ([BaseFrameData]) -> Void = { _ in },
        onProgressUpdate: @escaping (Double, String) -> Void = { _, _ in },
        onCompleted: @escaping (ComicResult) -> Void,
        onFailed: @escaping (String) -> Void
    ) async {
        print("🎬 开始完整连环画生成流程，任务ID: \(config.taskId)")
        
        await MainActor.run {
            self.generationStatus = .extractingBaseFrames
            self.generationProgress = 0
            self.errorMessage = nil
            self.comicResult = nil
        }
        
        do {
            // 第一步：提取基础帧
            let baseFrames = try await extractBaseFrames(taskId: config.taskId)
            print("✅ 基础帧提取完成，数量: \(baseFrames.count)")
            
            await MainActor.run {
                onBaseFramesExtracted(baseFrames)
                onProgressUpdate(0.3, "基础帧提取完成")
            }
            
            // 第二步：生成完整连环画
            try await generateCompleteComic(config: config)
            print("✅ 连环画生成已启动")
            
            await MainActor.run {
                self.generationStatus = .generatingComic
                onProgressUpdate(0.4, "连环画生成已启动")
            }
            
            // 第三步：轮询生成状态
            await pollComicGenerationStatus(
                taskId: config.taskId,
                onProgressUpdate: onProgressUpdate,
                onCompleted: onCompleted,
                onFailed: onFailed
            )
            
        } catch {
            print("❌ 连环画生成流程失败: \(error)")
            let errorMsg = "连环画生成失败: \(error.localizedDescription)"
            
            await MainActor.run {
                self.generationStatus = .failed
                self.errorMessage = errorMsg
            }
            
            onFailed(errorMsg)
        }
    }
    
    /// 尝试提前提取基础帧（在视频还在处理时）
    func tryEarlyBaseFrameExtraction(taskId: String) async -> [BaseFrameData] {
        print("🚀 尝试提前提取基础帧, taskId: \(taskId)")
        
        do {
            let baseFrames = try await extractBaseFrames(taskId: taskId)
            print("✅ 提前基础帧提取成功，数量: \(baseFrames.count)")
            return baseFrames
        } catch {
            print("⚠️ 提前基础帧提取失败: \(error)")
            return []
        }
    }
    
    // MARK: - Private Methods
    
    /// 提取基础帧
    private func extractBaseFrames(taskId: String) async throws -> [BaseFrameData] {
        print("📸 开始提取基础帧...")
        
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
        return frames
    }
    
    /// 生成完整连环画
    private func generateCompleteComic(config: GenerationConfig) async throws {
        print("🎨 开始生成完整连环画")
        
        let request = CompleteComicRequest(
            taskId: config.taskId,
            videoPath: config.videoPath,
            storyStyle: config.storyStyle,
            targetFrames: config.targetFrames,
            frameInterval: config.frameInterval,
            significanceWeight: config.significanceWeight,
            qualityWeight: config.qualityWeight,
            stylePrompt: config.stylePrompt,
            imageSize: config.imageSize,
            maxConcurrent: config.maxConcurrent
        )
        
        let response = try await comicGenerationService.startCompleteComicGeneration(request: request)
        print("✅ 连环画生成已启动: \(response.message)")
    }
    
    /// 轮询连环画生成状态
    private func pollComicGenerationStatus(
        taskId: String,
        onProgressUpdate: @escaping (Double, String) -> Void,
        onCompleted: @escaping (ComicResult) -> Void,
        onFailed: @escaping (String) -> Void
    ) async {
        await progressPollingService.pollComicGenerationStatus(
            taskId: taskId,
            onProgress: { [weak self] result in
                let progress = 0.4 + (Double(result.progress) / 100.0) * 0.5 // 40%-90%
                onProgressUpdate(progress, result.message)
                
                // 如果需要获取最终结果
                if result.shouldFetchResult {
                    Task {
                        await self?.fetchComicResult(
                            taskId: taskId,
                            onCompleted: onCompleted,
                            onFailed: onFailed
                        )
                    }
                }
            },
            onCompleted: { [weak self] in
                // 获取连环画结果
                Task {
                    await self?.fetchComicResult(
                        taskId: taskId,
                        onCompleted: onCompleted,
                        onFailed: onFailed
                    )
                }
            },
            onFailed: { [weak self] message in
                Task { @MainActor in
                    self?.generationStatus = .failed
                    self?.errorMessage = message
                }
                onFailed(message)
            }
        )
    }
    
    /// 获取连环画结果
    private func fetchComicResult(
        taskId: String,
        onCompleted: @escaping (ComicResult) -> Void,
        onFailed: @escaping (String) -> Void
    ) async {
        do {
            print("📖 获取连环画结果...")
            let resultResponse = try await comicGenerationService.getComicResult(taskId: taskId)
            
            if let comicResult = comicGenerationService.convertToComicResult(from: resultResponse, taskId: taskId) {
                print("✅ 连环画结果转换成功，共\(comicResult.panels.count)页")
                
                await MainActor.run {
                    self.comicResult = comicResult
                    self.generationStatus = .completed
                    self.generationProgress = 1.0
                }
                
                onCompleted(comicResult)
            } else {
                print("❌ 连环画结果转换失败")
                let errorMsg = "连环画结果转换失败"
                
                await MainActor.run {
                    self.generationStatus = .failed
                    self.errorMessage = errorMsg
                }
                
                onFailed(errorMsg)
            }
            
        } catch {
            print("❌ 获取连环画结果失败: \(error)")
            let errorMsg = "获取连环画结果失败: \(error.localizedDescription)"
            
            await MainActor.run {
                self.generationStatus = .failed
                self.errorMessage = errorMsg
            }
            
            onFailed(errorMsg)
        }
    }
    
    // MARK: - Public Control Methods
    
    /// 重置协调器状态
    func reset() {
        generationStatus = .idle
        generationProgress = 0
        errorMessage = nil
        comicResult = nil
        cancellables.removeAll()
    }
    
    /// 取消当前生成任务
    func cancelGeneration() {
        progressPollingService.stopProgressPolling()
        generationStatus = .cancelled
        cancellables.removeAll()
    }
}

// MARK: - Comic Generation Status
enum ComicGenerationStatus {
    case idle
    case extractingBaseFrames
    case generatingComic
    case completed
    case failed
    case cancelled
    
    var description: String {
        switch self {
        case .idle:
            return "待开始"
        case .extractingBaseFrames:
            return "提取基础帧中"
        case .generatingComic:
            return "生成连环画中"
        case .completed:
            return "已完成"
        case .failed:
            return "失败"
        case .cancelled:
            return "已取消"
        }
    }
}
