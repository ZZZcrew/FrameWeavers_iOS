import Foundation
import Combine

// MARK: - 视频上传服务
/// 负责视频文件的网络上传功能
/// 包括HTTP上传、multipart请求构建、上传进度监控、错误处理、超时管理等
class VideoUploadService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var uploadProgress: Double = 0
    @Published var uploadStatus: UploadStatus = .pending
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private var uploadTask: URLSessionUploadTask?
    private var uploadStartTime: Date?
    private var uploadProgressTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Upload Result
    struct UploadResult {
        let success: Bool
        let taskId: String?
        let videoPath: String?
        let uploadedFiles: Int?
        let invalidFiles: [String]?
        let message: String
    }
    
    // MARK: - 公共上传方法
    
    /// 上传视频文件
    /// - Parameter videoURLs: 要上传的视频文件URL数组
    /// - Returns: 上传结果的Publisher
    func uploadVideos(_ videoURLs: [URL]) -> AnyPublisher<UploadResult, Error> {
        return Future<UploadResult, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(VideoUploadError.serviceUnavailable))
                return
            }
            
            // 重置状态
            self.resetUploadState()
            
            // 开始上传
            self.performUpload(videoURLs: videoURLs) { result in
                switch result {
                case .success(let uploadResult):
                    promise(.success(uploadResult))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// 取消当前上传
    func cancelUpload() {
        uploadTask?.cancel()
        uploadTask = nil
        stopUploadProgressMonitoring()
        resetUploadState()
    }
    
    // MARK: - 私有上传实现
    
    private func performUpload(videoURLs: [URL], completion: @escaping (Result<UploadResult, Error>) -> Void) {
        let url = NetworkConfig.Endpoint.uploadVideos.url
        
        // 计算动态超时时间
        let dynamicTimeout = calculateDynamicTimeout(for: videoURLs)
        
        // 创建multipart/form-data请求
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = dynamicTimeout
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        do {
            let httpBody = try createMultipartBody(videoURLs: videoURLs, boundary: boundary)
            
            let session = URLSession.shared
            uploadTask = session.uploadTask(with: request, from: httpBody) { [weak self] data, response, error in
                DispatchQueue.main.async {
                    self?.stopUploadProgressMonitoring()
                    self?.handleUploadResponse(data: data, response: response, error: error, completion: completion)
                }
            }
            
            print("🚀 开始上传视频，动态超时: \(dynamicTimeout)秒")
            startUploadProgressMonitoring(expectedDuration: dynamicTimeout)
            uploadTask?.resume()
            
            // 更新状态
            DispatchQueue.main.async {
                self.uploadStatus = .uploading
                self.uploadProgress = 0
                self.errorMessage = nil
            }
            
        } catch {
            DispatchQueue.main.async {
                self.uploadStatus = .failed
                self.errorMessage = "创建上传请求失败: \(error.localizedDescription)"
            }
            completion(.failure(error))
        }
    }
    
    // MARK: - Multipart请求构建
    
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
    
    // MARK: - 超时计算
    
    private func calculateDynamicTimeout(for videoURLs: [URL]) -> TimeInterval {
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
    
    // MARK: - 上传进度监控
    
    private func startUploadProgressMonitoring(expectedDuration: TimeInterval) {
        uploadStartTime = Date()
        
        // 每10秒打印一次上传进度日志
        uploadProgressTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.uploadStartTime else { return }
            
            let elapsed = Date().timeIntervalSince(startTime)
            let progress = min(elapsed / expectedDuration * 100, 95) // 最多显示95%，避免超过100%
            
            print("📤 上传进行中... 已耗时: \(elapsed.formatted(.number.precision(.fractionLength(1))))秒 (预计进度: \(progress.formatted(.number.precision(.fractionLength(1))))%)")
            
            // 更新进度
            DispatchQueue.main.async {
                self.uploadProgress = progress / 100.0
            }
            
            // 如果超过预期时间的120%，给出警告
            if elapsed > expectedDuration * 1.2 {
                print("⚠️ 上传时间超过预期，可能遇到网络问题")
            }
        }
    }
    
    private func stopUploadProgressMonitoring() {
        uploadProgressTimer?.invalidate()
        uploadProgressTimer = nil
        uploadStartTime = nil
    }
    
    // MARK: - 响应处理
    
    private func handleUploadResponse(data: Data?, response: URLResponse?, error: Error?, completion: @escaping (Result<UploadResult, Error>) -> Void) {
        if let error = error {
            let processedError = processNetworkError(error)
            DispatchQueue.main.async {
                self.uploadStatus = .failed
                self.errorMessage = processedError.localizedDescription
            }
            completion(.failure(processedError))
            return
        }
        
        guard let data = data else {
            let error = VideoUploadError.noData
            DispatchQueue.main.async {
                self.uploadStatus = .failed
                self.errorMessage = error.localizedDescription
            }
            completion(.failure(error))
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = VideoUploadError.invalidResponse
            DispatchQueue.main.async {
                self.uploadStatus = .failed
                self.errorMessage = error.localizedDescription
            }
            completion(.failure(error))
            return
        }
        
        if httpResponse.statusCode == 200 {
            do {
                let response = try JSONDecoder().decode(RealUploadResponse.self, from: data)
                let uploadResult = UploadResult(
                    success: response.success,
                    taskId: response.task_id,
                    videoPath: response.video_path,
                    uploadedFiles: response.uploaded_files,
                    invalidFiles: response.invalid_files,
                    message: response.message
                )
                
                DispatchQueue.main.async {
                    if response.success {
                        self.uploadStatus = .processing
                        self.uploadProgress = 1.0
                        print("✅ 上传成功，任务ID: \(response.task_id ?? "未知")")
                        print("📊 上传文件数: \(response.uploaded_files ?? 0)")
                        if let invalidFiles = response.invalid_files, !invalidFiles.isEmpty {
                            print("⚠️ 无效文件: \(invalidFiles)")
                        }
                    } else {
                        self.uploadStatus = .failed
                        self.errorMessage = response.message
                    }
                }
                
                completion(.success(uploadResult))
            } catch {
                print("❌ JSON解析错误详情: \(error)")
                let parseError = VideoUploadError.parseError(error.localizedDescription)
                DispatchQueue.main.async {
                    self.uploadStatus = .failed
                    self.errorMessage = parseError.localizedDescription
                }
                completion(.failure(parseError))
            }
        } else {
            // 处理错误响应
            do {
                let errorResponse = try JSONDecoder().decode(RealUploadResponse.self, from: data)
                let uploadResult = UploadResult(
                    success: false,
                    taskId: nil,
                    videoPath: nil,
                    uploadedFiles: nil,
                    invalidFiles: nil,
                    message: errorResponse.message
                )
                DispatchQueue.main.async {
                    self.uploadStatus = .failed
                    self.errorMessage = errorResponse.message
                }
                completion(.success(uploadResult))
            } catch {
                let serverError = VideoUploadError.serverError(httpResponse.statusCode)
                DispatchQueue.main.async {
                    self.uploadStatus = .failed
                    self.errorMessage = serverError.localizedDescription
                }
                completion(.failure(serverError))
            }
        }
    }
    
    // MARK: - 错误处理
    
    private func processNetworkError(_ error: Error) -> VideoUploadError {
        let nsError = error as NSError
        print("❌ 上传错误详情:")
        print("   错误域: \(nsError.domain)")
        print("   错误代码: \(nsError.code)")
        print("   错误描述: \(error.localizedDescription)")
        
        // 参考Python脚本的错误分类处理
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorTimedOut:
                print("🔍 建议: 文件可能过大，建议压缩后重试")
                return .timeout
            case NSURLErrorNotConnectedToInternet:
                return .noInternet
            case NSURLErrorNetworkConnectionLost:
                return .connectionLost
            case NSURLErrorCannotConnectToHost:
                return .cannotConnectToHost
            case NSURLErrorCannotFindHost:
                return .cannotFindHost
            case NSURLErrorDataLengthExceedsMaximum:
                return .fileTooLarge
            default:
                return .networkError(nsError.code, error.localizedDescription)
            }
        } else {
            return .unknown(error.localizedDescription)
        }
    }
    
    // MARK: - 状态重置
    
    private func resetUploadState() {
        uploadProgress = 0
        uploadStatus = .pending
        errorMessage = nil
    }
}

// MARK: - 视频上传错误类型
enum VideoUploadError: LocalizedError {
    case serviceUnavailable
    case noData
    case invalidResponse
    case parseError(String)
    case serverError(Int)
    case timeout
    case noInternet
    case connectionLost
    case cannotConnectToHost
    case cannotFindHost
    case fileTooLarge
    case networkError(Int, String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .serviceUnavailable:
            return "上传服务不可用"
        case .noData:
            return "服务器未返回数据"
        case .invalidResponse:
            return "服务器响应格式无效"
        case .parseError(let details):
            return "解析响应失败: \(details)"
        case .serverError(let code):
            return "服务器错误 (\(code))"
        case .timeout:
            return "上传超时 - 请检查网络连接或尝试压缩视频后重新上传"
        case .noInternet:
            return "网络连接不可用 - 请检查网络设置"
        case .connectionLost:
            return "网络连接中断 - 请重新尝试上传"
        case .cannotConnectToHost:
            return "无法连接到服务器 - 请稍后重试"
        case .cannotFindHost:
            return "找不到服务器 - 请检查服务器地址"
        case .fileTooLarge:
            return "文件过大 - 请压缩视频后重试"
        case .networkError(let code, let description):
            return "网络错误 (\(code)): \(description)"
        case .unknown(let description):
            return "上传失败: \(description)"
        }
    }
}
