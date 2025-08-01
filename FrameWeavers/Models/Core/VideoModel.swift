import Foundation
import UIKit

// MARK: - 基础帧数据模型
struct BaseFrameData: Identifiable, Hashable {
    let id = UUID()
    let framePath: String
    let frameIndex: Int
    let timestamp: Double
    let thumbnailURL: URL?

    init(framePath: String, frameIndex: Int, timestamp: Double) {
        self.framePath = framePath
        self.frameIndex = frameIndex
        self.timestamp = timestamp
        // 构建完整的图片URL
        if framePath.hasPrefix("http") {
            self.thumbnailURL = URL(string: framePath)
        } else {
            // 如果是相对路径，需要拼接服务器地址
            let baseURL = NetworkConfig.baseURL
            // 修复Windows路径分隔符问题：将反斜杠替换为正斜杠
            let normalizedPath = framePath.replacingOccurrences(of: "\\", with: "/")
            let fullURL = "\(baseURL)/\(normalizedPath)"
            self.thumbnailURL = URL(string: fullURL)
            print("🔗 BaseFrameData: 原始路径: \(framePath)")
            print("🔗 BaseFrameData: 标准化路径: \(normalizedPath)")
            print("🔗 BaseFrameData: 完整URL: \(fullURL)")

            // 测试URL是否可访问
            if let url = self.thumbnailURL {
                Task {
                    do {
                        // 创建带有正确头部的请求
                        var request = URLRequest(url: url)
                        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
                        request.setValue("*/*", forHTTPHeaderField: "Accept")
                        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
                        request.setValue("keep-alive", forHTTPHeaderField: "Connection")

                        let (data, response) = try await URLSession.shared.data(for: request)
                        if let httpResponse = response as? HTTPURLResponse {
                            print("🌐 URL测试: \(fullURL) - 状态码: \(httpResponse.statusCode)")
                            print("📊 响应头: \(httpResponse.allHeaderFields)")
                            print("📦 数据大小: \(data.count) bytes")
                        }
                    } catch {
                        print("❌ URL测试失败: \(fullURL) - 错误: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}

// MARK: - 关键帧数据模型
struct KeyFrameData: Identifiable, Hashable {
    let id = UUID()
    let framePath: String
    let frameIndex: Int
    let timestamp: Double
    let importance: Double // 关键帧的重要性评分
    let thumbnailURL: URL?

    init(framePath: String, frameIndex: Int, timestamp: Double, importance: Double = 1.0) {
        self.framePath = framePath
        self.frameIndex = frameIndex
        self.timestamp = timestamp
        self.importance = importance
        
        // 构建完整的图片URL
        if framePath.hasPrefix("http") {
            self.thumbnailURL = URL(string: framePath)
        } else {
            let baseURL = NetworkConfig.baseURL
            let normalizedPath = framePath.replacingOccurrences(of: "\\", with: "/")
            let fullURL = "\(baseURL)/\(normalizedPath)"
            self.thumbnailURL = URL(string: fullURL)
        }
    }
}

// MARK: - 视频元数据
struct VideoMetadata: Codable {
    let fileName: String
    let fileSize: Int64
    let duration: Double
    let format: String
    let resolution: String?
    let frameRate: Double?
    let bitrate: Int64?
    
    init(fileName: String, fileSize: Int64, duration: Double, format: String, resolution: String? = nil, frameRate: Double? = nil, bitrate: Int64? = nil) {
        self.fileName = fileName
        self.fileSize = fileSize
        self.duration = duration
        self.format = format
        self.resolution = resolution
        self.frameRate = frameRate
        self.bitrate = bitrate
    }
}

// MARK: - 设备ID生成器
struct DeviceIDGenerator {
    /// 生成设备唯一标识符
    /// - Returns: 设备ID字符串
    static func generateDeviceID() -> String {
        // 优先使用 identifierForVendor
        if let vendorId = UIDevice.current.identifierForVendor?.uuidString {
            return vendorId
        }
        
        // 备用方案：生成并存储UUID
        let key = "FrameWeavers_DeviceID"
        if let storedId = UserDefaults.standard.string(forKey: key) {
            return storedId
        }
        
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: key)
        return newId
    }
}

// MARK: - 基础帧服务
class BaseFrameService {
    private let baseURL: String
    
    init(baseURL: String = NetworkConfig.baseURL) {
        self.baseURL = baseURL
    }
    
    func extractBaseFrames(taskId: String, interval: Double = 1.0) async throws -> BaseFrameExtractionResponse {
        let endpoint = "/api/extract/base-frames"
        let urlString = baseURL + endpoint
        print("🌐 BaseFrameService: 请求URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ BaseFrameService: 无效的URL: \(urlString)")
            throw NSError(domain: "BaseFrameService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的URL"])
        }
        
        let parameters = [
            "task_id": taskId,
            "interval": String(interval)
        ]
        print("📝 BaseFrameService: 请求参数: \(parameters)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyString = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        print("📤 BaseFrameService: 请求体: \(bodyString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        print("📥 BaseFrameService: 收到响应")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ BaseFrameService: 无效的HTTP响应")
            throw NSError(domain: "BaseFrameService", code: -2, userInfo: [NSLocalizedDescriptionKey: "无效的HTTP响应"])
        }
        
        print("📊 BaseFrameService: HTTP状态码: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            print("❌ BaseFrameService: 服务器错误，状态码: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 BaseFrameService: 错误响应内容: \(responseString)")
            }
            throw NSError(domain: "BaseFrameService", code: -2, userInfo: [NSLocalizedDescriptionKey: "服务器错误: \(httpResponse.statusCode)"])
        }
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 BaseFrameService: 响应内容: \(responseString)")
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(BaseFrameExtractionResponse.self, from: data)
    }
}
