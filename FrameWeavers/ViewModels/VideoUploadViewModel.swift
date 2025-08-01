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
    @Published var selectedVideos: [URL] = []  // 支持多视频
    @Published var uploadStatus: UploadStatus = .pending
    @Published var uploadProgress: Double = 0
    @Published var errorMessage: String?
    @Published var comicResult: ComicResult?
    @Published var isShowingPicker = false
    @Published var baseFrames: [BaseFrameData] = [] // 基础帧数据
    @Published var keyFrames: [KeyFrameData] = [] // 关键帧数据
    @Published var shouldNavigateToStyleSelection = false // 导航状态
    @Published var selectedStyle: String = "" // 选择的故事风格
    // 移除 shouldNavigateToProcessing，改用NavigationLink

    private var cancellables = Set<AnyCancellable>()
    private var uploadTask: URLSessionUploadTask?
    private var currentTaskId: String?  // 当前任务ID
    private var currentVideoPath: String?  // 当前视频路径
    private var progressTimer: Timer?   // 进度查询定时器
    private var uploadStartTime: Date?  // 上传开始时间
    private var uploadProgressTimer: Timer?  // 上传进度监控定时器
    private let baseFrameService = BaseFrameService() // 基础帧服务
    private let comicGenerationService = ComicGenerationService() // 连环画生成服务
    private var historyService: HistoryService? // 历史记录服务

    // MARK: - 初始化和配置

    /// 设置历史记录服务
    /// - Parameter modelContext: SwiftData模型上下文
    func setHistoryService(modelContext: ModelContext) {
        self.historyService = HistoryService(modelContext: modelContext)
    }

    // 兼容性属性，返回第一个选中的视频
    var selectedVideo: URL? {
        return selectedVideos.first
    }
    
    func selectVideo(_ url: URL) {
        selectedVideos = [url]  // 单视频选择
        validateVideos()
    }

    func selectVideos(_ urls: [URL]) {
        selectedVideos = urls  // 多视频选择
        validateVideos()
        // 选择视频后自动触发导航
        if !urls.isEmpty {
            shouldNavigateToStyleSelection = true
        }
    }

    func addVideo(_ url: URL) {
        selectedVideos.append(url)
        validateVideos()
    }

    func removeVideo(at index: Int) {
        guard index < selectedVideos.count else { return }
        selectedVideos.remove(at: index)
        validateVideos()
    }

    /// 保存视频数据到临时文件
    /// - Parameter data: 视频数据
    /// - Returns: 保存的文件URL，失败时返回nil
    func saveVideoData(_ data: Data) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "temp_video_\(UUID().uuidString).mp4"
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            print("✅ 视频保存成功: \(fileURL.lastPathComponent)")
            return fileURL
        } catch {
            print("❌ 保存视频失败: \(error)")
            errorMessage = "保存视频失败: \(error.localizedDescription)"
            return nil
        }
    }

    /// 处理PhotosPicker选择的视频项目（优化版本）
    /// - Parameter items: PhotosPicker选择的项目数组
    /// - Returns: 处理完成的视频URL数组
    func processSelectedItems(_ items: [PickerItem]) async -> [URL] {
        var videoURLs: [URL] = []

        // 更新处理状态
        await MainActor.run {
            self.uploadStatus = .processing
            self.errorMessage = "正在处理选中的视频..."
        }

        for (index, item) in items.enumerated() {
            do {
                // 更新进度提示
                await MainActor.run {
                    self.errorMessage = "正在处理第 \(index + 1)/\(items.count) 个视频..."
                }

                // 优化：使用URL方式而不是Data方式，避免全量内存加载
                if let url = try await item.loadTransferable(type: URL.self) {
                    // 直接使用系统提供的临时URL，无需重新保存
                    videoURLs.append(url)
                    print("✅ 视频处理成功: \(url.lastPathComponent)")
                } else if let data = try await item.loadTransferable(type: Data.self),
                          let savedUrl = saveVideoData(data) {
                    // 备用方案：如果URL方式失败，使用Data方式
                    videoURLs.append(savedUrl)
                    print("✅ 视频保存成功（备用方案）: \(savedUrl.lastPathComponent)")
                }
            } catch {
                print("❌ 处理视频项目失败: \(error)")
                await MainActor.run {
                    self.errorMessage = "处理第 \(index + 1) 个视频失败: \(error.localizedDescription)"
                }
            }
        }

        // 清除处理状态提示
        await MainActor.run {
            self.errorMessage = nil
            self.uploadStatus = .pending
        }

        return videoURLs
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

        guard !selectedVideos.isEmpty else {
            print("❌ 没有选择视频")
            errorMessage = "请先选择视频"
            return false
        }

        print("✅ 开始生成连环画")
        print("📊 故事风格: \(selectedStyle)")
        print("📊 当前状态: \(uploadStatus.rawValue)")
        print("📊 视频数量: \(selectedVideos.count)")

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

    private func validateVideos() {
        guard !selectedVideos.isEmpty else {
            errorMessage = nil
            uploadStatus = .pending
            return
        }

        // 异步验证所有视频，提高性能
        Task {
            await MainActor.run {
                self.errorMessage = "正在验证视频..."
                self.uploadStatus = .processing
            }

            // 使用actor-isolated的结果结构体来避免并发访问问题
            struct ValidationResult {
                let hasError: Bool
                let errorMessage: String?
            }

            // 并发验证所有视频以提高性能
            let validationResult = await withTaskGroup(of: (Int, Result<(Double, Int64), Error>).self) { group in
                for (index, url) in selectedVideos.enumerated() {
                    group.addTask {
                        let asset = AVAsset(url: url)
                        do {
                            // 获取时长
                            let duration = try await asset.load(.duration)
                            let durationSeconds = CMTimeGetSeconds(duration)

                            // 获取文件大小
                            let fileSize = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0

                            return (index, .success((durationSeconds, Int64(fileSize))))
                        } catch {
                            return (index, .failure(error))
                        }
                    }
                }

                // 收集所有结果
                var hasError = false
                var errorMsg = ""
                let maxFileSize: Int64 = 800 * 1024 * 1024 // 800MB限制，与服务器保持一致

                for await (index, result) in group {
                    switch result {
                    case .success(let (durationSeconds, fileSize)):
                        if durationSeconds > 300 { // 5分钟
                            hasError = true
                            errorMsg = "视频\(index + 1)时长超过5分钟（\(Int(durationSeconds))秒）"
                            break
                        } else if fileSize > maxFileSize {
                            let fileSizeMB = Double(fileSize) / (1024 * 1024)
                            hasError = true
                            errorMsg = "视频\(index + 1)文件过大（\(String(format: "%.1f", fileSizeMB))MB），请选择小于800MB的视频"
                            break
                        }
                    case .failure(_):
                        hasError = true
                        errorMsg = "无法获取视频\(index + 1)的信息"
                        break
                    }
                }

                return ValidationResult(hasError: hasError, errorMessage: hasError ? errorMsg : nil)
            }

            await MainActor.run {
                if validationResult.hasError {
                    self.errorMessage = validationResult.errorMessage
                    self.uploadStatus = .failed
                } else {
                    self.errorMessage = nil
                    self.uploadStatus = .pending
                    print("✅ 所有视频验证通过")
                }
            }
        }
    }
    
    func uploadVideo() {
        guard !selectedVideos.isEmpty else { return }

        uploadStatus = .uploading
        uploadProgress = 0
        errorMessage = nil

        uploadVideosReal(videoURLs: selectedVideos)  // 仅使用真实上传模式
    }

    /// 根据文件大小计算动态超时时间
    /// - Parameter videoURLs: 视频文件URL数组
    /// - Returns: 计算出的超时时间（秒）
    private func calculateDynamicTimeout(for videoURLs: [URL]) -> TimeInterval {
        // 简化实现：直接使用基础超时，避免类型转换问题
        let baseTimeout = NetworkConfig.uploadTimeoutInterval  // 300秒基础超时

        // 检查是否有多个文件或大文件，如果有则使用更长超时
        if videoURLs.count > 1 {
            let extendedTimeout = baseTimeout * 2  // 多文件使用2倍超时
            print("🔄 多文件检测，使用扩展超时: \(extendedTimeout)秒")
            return extendedTimeout
        } else {
            print("🔄 单文件，使用基础超时: \(baseTimeout)秒")
            return baseTimeout
        }
    }

    /// 开始上传进度监控
    /// - Parameter expectedDuration: 预期上传时长（秒）
    private func startUploadProgressMonitoring(expectedDuration: TimeInterval) {
        uploadStartTime = Date()

        // 每10秒打印一次上传进度日志
        uploadProgressTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.uploadStartTime else { return }

            let elapsed = Date().timeIntervalSince(startTime)
            let progress = min(elapsed / expectedDuration * 100, 95) // 最多显示95%，避免超过100%

            print("📤 上传进行中... 已耗时: \(elapsed.formatted(.number.precision(.fractionLength(1))))秒 (预计进度: \(progress.formatted(.number.precision(.fractionLength(1))))%)")

            // 如果超过预期时间的120%，给出警告
            if elapsed > expectedDuration * 1.2 {
                print("⚠️ 上传时间超过预期，可能遇到网络问题")
            }
        }
    }

    /// 停止上传进度监控
    private func stopUploadProgressMonitoring() {
        uploadProgressTimer?.invalidate()
        uploadProgressTimer = nil

        if let startTime = uploadStartTime {
            let totalTime = Date().timeIntervalSince(startTime)
            print("📊 上传总耗时: \(totalTime.formatted(.number.precision(.fractionLength(2))))秒")
        }

        uploadStartTime = nil
    }

    // MARK: - 真实HTTP上传（支持多视频）
    private func uploadVideosReal(videoURLs: [URL]) {
        let url = NetworkConfig.Endpoint.uploadVideos.url

        // 计算动态超时时间
        let dynamicTimeout = calculateDynamicTimeout(for: videoURLs)

        // 创建multipart/form-data请求
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = dynamicTimeout  // 使用动态超时

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        do {
            let httpBody = try createMultipartBody(videoURLs: videoURLs, boundary: boundary)

            let session = URLSession.shared
            uploadTask = session.uploadTask(with: request, from: httpBody) { [weak self] data, response, error in
                DispatchQueue.main.async {
                    self?.stopUploadProgressMonitoring()  // 停止进度监控
                    self?.handleRealUploadResponse(data: data, response: response, error: error)
                }
            }

            print("🚀 开始上传视频，动态超时: \(dynamicTimeout)秒")
            startUploadProgressMonitoring(expectedDuration: dynamicTimeout)  // 开始进度监控
            uploadTask?.resume()

        } catch {
            errorMessage = "创建上传请求失败: \(error.localizedDescription)"
            uploadStatus = .failed
        }
    }

    private func createMultipartBody(videoURLs: [URL], boundary: String) throws -> Data {
        var body = Data()

        // 添加必需的device_id参数
        let deviceId = DeviceIDGenerator.generateDeviceID()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"device_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(deviceId)\r\n".data(using: .utf8)!)

        // 添加视频文件
        for videoURL in videoURLs {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"videos\"; filename=\"\(videoURL.lastPathComponent)\"\r\n".data(using: .utf8)!)

            // 根据文件扩展名设置正确的Content-Type
            let mimeType = getMimeType(for: videoURL)
            body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)

            let videoData = try Data(contentsOf: videoURL)
            body.append(videoData)
            body.append("\r\n".data(using: .utf8)!)
        }

        // 结束边界
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        return body
    }

    private func getMimeType(for url: URL) -> String {
        let fileExtension = url.pathExtension.lowercased()
        switch fileExtension {
        case "mp4":
            return "video/mp4"
        case "mov":
            return "video/quicktime"
        case "avi":
            return "video/x-msvideo"
        case "mkv":
            return "video/x-matroska"
        case "wmv":
            return "video/x-ms-wmv"
        case "flv":
            return "video/x-flv"
        case "3gp":
            return "video/3gpp"
        default:
            return "video/mp4"  // 默认
        }
    }

    private func handleRealUploadResponse(data: Data?, response: URLResponse?, error: Error?) {
        if let error = error {
            let nsError = error as NSError
            print("❌ 上传错误详情:")
            print("   错误域: \(nsError.domain)")
            print("   错误代码: \(nsError.code)")
            print("   错误描述: \(error.localizedDescription)")

            // 参考Python脚本的错误分类处理
            if nsError.domain == NSURLErrorDomain {
                switch nsError.code {
                case NSURLErrorTimedOut:
                    errorMessage = "上传超时 - 请检查网络连接或尝试压缩视频后重新上传"
                    print("🔍 建议: 文件可能过大，建议压缩后重试")
                case NSURLErrorNotConnectedToInternet:
                    errorMessage = "网络连接不可用 - 请检查网络设置"
                case NSURLErrorNetworkConnectionLost:
                    errorMessage = "网络连接中断 - 请重新尝试上传"
                case NSURLErrorCannotConnectToHost:
                    errorMessage = "无法连接到服务器 - 请稍后重试"
                case NSURLErrorCannotFindHost:
                    errorMessage = "找不到服务器 - 请检查服务器地址"
                case NSURLErrorDataLengthExceedsMaximum:
                    errorMessage = "文件过大 - 请压缩视频后重试"
                default:
                    errorMessage = "网络错误 (\(nsError.code)): \(error.localizedDescription)"
                }
            } else {
                errorMessage = "上传失败: \(error.localizedDescription)"
            }

            uploadStatus = .failed
            return
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            errorMessage = "无效的服务器响应"
            uploadStatus = .failed
            return
        }

        guard let data = data else {
            errorMessage = "没有收到响应数据"
            uploadStatus = .failed
            return
        }

        // 添加调试信息
        print("HTTP状态码: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("服务器响应内容: \(responseString)")
        }

        if httpResponse.statusCode == 200 {
            do {
                let response = try JSONDecoder().decode(RealUploadResponse.self, from: data)
                if response.success, let taskId = response.task_id {
                    print("上传成功，任务ID: \(taskId)")
                    print("上传文件数: \(response.uploaded_files ?? 0)")
                    if let invalidFiles = response.invalid_files, !invalidFiles.isEmpty {
                        print("无效文件: \(invalidFiles)")
                    }

                    // 保存视频路径
                    if let videoPath = response.video_path {
                        currentVideoPath = videoPath
                        print("📹 保存视频路径: \(videoPath)")
                    }

                    currentTaskId = taskId
                    uploadStatus = .processing
                    startProgressPolling(taskId: taskId)  // 开始轮询进度
                } else {
                    errorMessage = response.message
                    uploadStatus = .failed
                }
            } catch {
                print("JSON解析错误详情: \(error)")
                if let decodingError = error as? DecodingError {
                    print("解码错误详情: \(decodingError)")
                }
                errorMessage = "解析响应失败: \(error.localizedDescription)"
                uploadStatus = .failed
            }
        } else {
            // 处理错误响应
            do {
                let errorResponse = try JSONDecoder().decode(RealUploadResponse.self, from: data)
                errorMessage = errorResponse.message
            } catch {
                errorMessage = "服务器错误 (\(httpResponse.statusCode))"
            }
            uploadStatus = .failed
        }
    }
    
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
        let videoTitle = selectedVideos.isEmpty ? "测试视频.mp4" : selectedVideos.map { $0.lastPathComponent }.joined(separator: ", ")

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
        // 取消上传任务
        uploadTask?.cancel()
        uploadTask = nil

        // 停止进度轮询
        progressTimer?.invalidate()
        progressTimer = nil

        // 停止上传进度监控
        stopUploadProgressMonitoring()

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
        selectedVideos = []
        uploadStatus = .pending
        uploadProgress = 0
        errorMessage = nil
        comicResult = nil
        cancellables.removeAll()
        uploadTask?.cancel()
        uploadTask = nil
        progressTimer?.invalidate()
        progressTimer = nil
        currentTaskId = nil
        currentVideoPath = nil  // 清理视频路径

        // 停止上传进度监控
        stopUploadProgressMonitoring()
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
