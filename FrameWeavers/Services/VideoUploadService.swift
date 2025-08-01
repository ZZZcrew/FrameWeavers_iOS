import Foundation
import AVFoundation
import Network

protocol VideoUploadServiceProtocol {
    func uploadVideos(videoURLs: [URL], progressHandler: @escaping (Double) -> Void) async throws -> UploadResponse
    func cancelCurrentUpload()
}

class VideoUploadService: VideoUploadServiceProtocol {
    private var uploadTask: URLSessionUploadTask?
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    
    func uploadVideos(videoURLs: [URL], progressHandler: @escaping (Double) -> Void = { _ in }) async throws -> UploadResponse {
        guard !videoURLs.isEmpty else {
            throw VideoUploadError.noVideosSelected
        }
        
        let url = NetworkConfig.Endpoint.uploadVideos.url
        let dynamicTimeout = calculateDynamicTimeout(for: videoURLs)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = dynamicTimeout
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let httpBody = try createMultipartBody(videoURLs: videoURLs, boundary: boundary)
        
        return try await withCheckedThrowingContinuation { continuation in
            let session = URLSession.shared
            
            uploadTask = session.uploadTask(with: request, from: httpBody) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: self.handleNetworkError(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    continuation.resume(throwing: VideoUploadError.invalidResponse)
                    return
                }
                
                guard let data = data else {
                    continuation.resume(throwing: VideoUploadError.noData)
                    return
                }
                
                do {
                    let uploadResponse = try JSONDecoder().decode(UploadResponse.self, from: data)
                    if httpResponse.statusCode == 200 && uploadResponse.success {
                        continuation.resume(returning: uploadResponse)
                    } else {
                        let errorMessage = uploadResponse.message ?? "Upload failed"
                        continuation.resume(throwing: VideoUploadError.serverError(errorMessage))
                    }
                } catch {
                    continuation.resume(throwing: VideoUploadError.decodingError(error))
                }
            }
            
            uploadTask?.resume()
        }
    }
    
    func cancelCurrentUpload() {
        uploadTask?.cancel()
        uploadTask = nil
    }
    
    private func calculateDynamicTimeout(for videoURLs: [URL]) -> TimeInterval {
        let baseTimeout = NetworkConfig.uploadTimeoutInterval
        
        if videoURLs.count > 1 {
            let totalSize = videoURLs.reduce(0) { total, url in
                (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0 + total
            }
            let sizeInMB = Double(totalSize) / (1024 * 1024)
            let multiplier = min(max(sizeInMB / 100.0, 1.0), 4.0) // 限制上限为4倍基础超时
            return baseTimeout * multiplier
        } else if let fileSize = try? videoURLs[0].resourceValues(forKeys: [.fileSizeKey]).fileSize {
            let sizeInMB = Double(fileSize) / (1024 * 1024)
            let multiplier = min(max(sizeInMB / 200.0, 1.0), 3.0) // 限制上限为3倍基础超时
            return baseTimeout * multiplier
        }
        
        return baseTimeout
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
            
            let mimeType = getMimeType(for: videoURL)
            body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            
            let videoData = try Data(contentsOf: videoURL)
            body.append(videoData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return body
    }
    
    private func getMimeType(for url: URL) -> String {
        let fileExtension = url.pathExtension.lowercased()
        switch fileExtension {
        case "mp4": return "video/mp4"
        case "mov": return "video/quicktime"
        case "avi": return "video/x-msvideo"
        case "mkv": return "video/x-matroska"
        case "wmv": return "video/x-ms-wmv"
        case "flv": return "video/x-flv"
        case "3gp": return "video/3gpp"
        default: return "video/mp4"
        }
    }
    
    private func handleNetworkError(_ error: Error) -> VideoUploadError {
        let nsError = error as NSError
        
        switch nsError.code {
        case NSURLErrorTimedOut:
            return .timeout
        case NSURLErrorNotConnectedToInternet:
            return .noInternetConnection
        case NSURLErrorNetworkConnectionLost:
            return .connectionLost
        case NSURLErrorCannotConnectToHost:
            return .cannotConnectToHost
        case NSURLErrorCannotFindHost:
            return .cannotFindHost
        case NSURLErrorDataLengthExceedsMaximum:
            return .fileTooLarge
        default:
            return .networkError(error.localizedDescription)
        }
    }
}

// MARK: - 数据模型
struct UploadResponse: Codable {
    let success: Bool
    let message: String?
    let task_id: String?
    let uploaded_files: Int?
    let invalid_files: [String]?
    let video_path: String?
}

enum VideoUploadError: Error, LocalizedError {
    case noVideosSelected
    case networkError(String)
    case timeout
    case noInternetConnection
    case connectionLost
    case cannotConnectToHost
    case cannotFindHost
    case fileTooLarge
    case invalidResponse
    case noData
    case serverError(String)
    case decodingError(Error)
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .noVideosSelected:
            return "请至少选择一个视频"
        case .timeout:
            return "上传超时 - 请检查网络连接或尝试压缩视频后重新上传"
        case .noInternetConnection:
            return "网络连接不可用 - 请检查网络设置"
        case .connectionLost:
            return "网络连接中断 - 请重新尝试上传"
        case .cannotConnectToHost:
            return "无法连接到服务器 - 请稍后重试"
        case .cannotFindHost:
            return "找不到服务器 - 请检查服务器地址"
        case .fileTooLarge:
            return "文件过大 - 请压缩视频后重试"
        case .invalidResponse:
            return "服务器响应无效"
        case .noData:
            return "没有收到响应数据"
        case .serverError(let message):
            return "服务器错误: \(message)"
        case .networkError(let message):
            return "网络错误: \(message)"
        case .decodingError(let error):
            return "解析响应失败: \(error.localizedDescription)"
        case .cancelled:
            return "上传已取消"
        }
    }
}