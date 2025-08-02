import Foundation
import Combine

// MARK: - 进度轮询服务
/// 负责任务进度查询和状态轮询功能
/// 包括任务状态查询、连环画生成状态轮询、后端任务取消等
@Observable
class ProgressPollingService {
    
    // MARK: - Published Properties
    var uploadProgress: Double = 0
    var uploadStatus: UploadStatus = .pending
    var errorMessage: String?
    
    // MARK: - Private Properties
    private var progressTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Progress Polling Result
    struct ProgressResult {
        let status: String
        let progress: Int
        let message: String
        let stage: String?
        let shouldContinue: Bool
        let shouldExtractFrames: Bool
        let shouldTryEarlyExtraction: Bool
    }
    
    // MARK: - Comic Generation Progress Result
    struct ComicProgressResult {
        let isCompleted: Bool
        let isFailed: Bool
        let progress: Int
        let stage: String?
        let message: String
        let shouldFetchResult: Bool
    }
    
    // MARK: - Deinitializer
    deinit {
        stopProgressPolling()
    }
    
    // MARK: - 基础任务状态轮询
    
    /// 开始进度轮询
    /// - Parameters:
    ///   - taskId: 任务ID
    ///   - onProgress: 进度更新回调
    ///   - onCompleted: 完成回调
    ///   - onFailed: 失败回调
    func startProgressPolling(
        taskId: String,
        onProgress: @escaping (ProgressResult) -> Void,
        onCompleted: @escaping () -> Void,
        onFailed: @escaping (String) -> Void
    ) {
        stopProgressPolling()
        
        progressTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkTaskStatus(
                taskId: taskId,
                onProgress: onProgress,
                onCompleted: onCompleted,
                onFailed: onFailed
            )
        }
    }
    
    /// 停止进度轮询
    func stopProgressPolling() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    /// 检查任务状态
    private func checkTaskStatus(
        taskId: String,
        onProgress: @escaping (ProgressResult) -> Void,
        onCompleted: @escaping () -> Void,
        onFailed: @escaping (String) -> Void
    ) {
        let url = NetworkConfig.Endpoint.taskStatus(taskId: taskId).url
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.handleTaskStatusResponse(
                    data: data,
                    response: response,
                    error: error,
                    onProgress: onProgress,
                    onCompleted: onCompleted,
                    onFailed: onFailed
                )
            }
        }.resume()
    }
    
    /// 处理任务状态响应
    private func handleTaskStatusResponse(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        onProgress: @escaping (ProgressResult) -> Void,
        onCompleted: @escaping () -> Void,
        onFailed: @escaping (String) -> Void
    ) {
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
                let stage = jsonObject["stage"] as? String
                
                // 更新进度
                uploadProgress = Double(progress) / 100.0
                
                print("任务状态: \(status), 进度: \(progress)%")
                
                // 创建结果对象
                let result: ProgressResult
                
                if status == "completed" {
                    uploadStatus = .processing // 先设置为处理中
                    result = ProgressResult(
                        status: status,
                        progress: progress,
                        message: message,
                        stage: stage,
                        shouldContinue: false,
                        shouldExtractFrames: true,
                        shouldTryEarlyExtraction: false
                    )
                    stopProgressPolling()
                } else if status == "processing" || status == "uploaded" {
                    // 视频正在处理中，可以尝试提前提取基础帧
                    uploadStatus = .processing
                    result = ProgressResult(
                        status: status,
                        progress: progress,
                        message: message,
                        stage: stage,
                        shouldContinue: true,
                        shouldExtractFrames: false,
                        shouldTryEarlyExtraction: true
                    )
                } else if status == "error" || status == "cancelled" {
                    uploadStatus = .failed
                    errorMessage = message
                    result = ProgressResult(
                        status: status,
                        progress: progress,
                        message: message,
                        stage: stage,
                        shouldContinue: false,
                        shouldExtractFrames: false,
                        shouldTryEarlyExtraction: false
                    )
                    stopProgressPolling()
                    onFailed(message)
                    return
                } else {
                    // 处理中或上传完成等待处理
                    uploadStatus = .processing
                    result = ProgressResult(
                        status: status,
                        progress: progress,
                        message: message,
                        stage: stage,
                        shouldContinue: true,
                        shouldExtractFrames: false,
                        shouldTryEarlyExtraction: false
                    )
                }
                
                // 调用进度回调
                onProgress(result)
                
                // 如果需要提取基础帧，调用完成回调
                if result.shouldExtractFrames {
                    onCompleted()
                }
            }
        } catch {
            print("解析状态响应失败: \(error)")
        }
    }
    
    // MARK: - 连环画生成状态轮询
    
    /// 轮询连环画生成状态
    /// - Parameters:
    ///   - taskId: 任务ID
    ///   - onProgress: 进度更新回调
    ///   - onCompleted: 完成回调
    ///   - onFailed: 失败回调
    func pollComicGenerationStatus(
        taskId: String,
        onProgress: @escaping (ComicProgressResult) -> Void,
        onCompleted: @escaping () -> Void,
        onFailed: @escaping (String) -> Void
    ) async {
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
                        let result = ComicProgressResult(
                            isCompleted: false,
                            isFailed: false,
                            progress: lastProgress,
                            stage: nil,
                            message: "连续错误过多，尝试获取最终结果",
                            shouldFetchResult: true
                        )
                        await MainActor.run {
                            onProgress(result)
                        }
                        onCompleted()
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
                    
                    let result = ComicProgressResult(
                        isCompleted: false,
                        isFailed: false,
                        progress: statusResponse.progress,
                        stage: stage,
                        message: stageDesc,
                        shouldFetchResult: false
                    )
                    
                    await MainActor.run {
                        self.uploadProgress = Double(statusResponse.progress) / 100.0
                        onProgress(result)
                    }
                }
                
                // 检查完成状态，参考Python实现
                if statusResponse.status == "complete_comic_completed" {
                    print("✅ 连环画生成完成！")
                    let result = ComicProgressResult(
                        isCompleted: true,
                        isFailed: false,
                        progress: statusResponse.progress,
                        stage: statusResponse.stage,
                        message: "连环画生成完成",
                        shouldFetchResult: true
                    )
                    await MainActor.run {
                        onProgress(result)
                    }
                    onCompleted()
                    return
                } else if statusResponse.status == "complete_comic_failed" || statusResponse.status == "error" {
                    print("❌ 连环画生成失败: \(statusResponse.message)")
                    let result = ComicProgressResult(
                        isCompleted: false,
                        isFailed: true,
                        progress: statusResponse.progress,
                        stage: statusResponse.stage,
                        message: "连环画生成失败: \(statusResponse.message)",
                        shouldFetchResult: false
                    )
                    await MainActor.run {
                        onProgress(result)
                    }
                    onFailed("连环画生成失败: \(statusResponse.message)")
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
        onFailed("连环画生成监控超时，请稍后重试")
    }
    
    // MARK: - 后端任务取消
    
    /// 取消后端任务
    /// - Parameter taskId: 任务ID
    func cancelBackendTask(taskId: String) {
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
    
    // MARK: - 重置和清理
    
    /// 重置服务状态
    func reset() {
        stopProgressPolling()
        uploadProgress = 0
        uploadStatus = .pending
        errorMessage = nil
        cancellables.removeAll()
    }
}
