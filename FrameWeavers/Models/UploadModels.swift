import Foundation
import SwiftData

// MARK: - Enums
enum UploadStatus: String, CaseIterable {
    case pending = "pending"
    case uploading = "uploading"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    
    var localizedDescription: String {
        switch self {
        case .pending: return "待处理"
        case .uploading: return "上传中"
        case .processing: return "处理中"
        case .completed: return "已完成"
        case .failed: return "失败"
        }
    }
}

// MARK: - 数据模型
struct BaseFrameData: Identifiable, Hashable {
    let id = UUID()
    let framePath: String
    let frameIndex: Int
    let timestamp: Double
    
    init(framePath: String, frameIndex: Int, timestamp: Double) {
        self.framePath = framePath
        self.frameIndex = frameIndex
        self.timestamp = timestamp
    }
}

struct KeyFrameData: Identifiable, Hashable {
    let id = UUID()
    let framePath: String
    let frameIndex: Int
    let timestamp: Double
    let significance: Double
    
    init(framePath: String, frameIndex: Int, timestamp: Double, significance: Double) {
        self.framePath = framePath
        self.frameIndex = frameIndex
        self.timestamp = timestamp
        self.significance = significance
    }
}

// MARK: - 网络配置
struct NetworkConfig {
    static let baseURL = "https://your-api-url.com"
    static let uploadTimeoutInterval: TimeInterval = 300.0
    static let comicGenerationTimeout: TimeInterval = 3000.0
    static let requestTimeout: TimeInterval = 30.0
    
    struct Endpoint {
        let method: String
        let path: String
        
        var url: URL {
            URL(string: "\(baseURL)\(path)")!
        }
        
        static let uploadVideos = Endpoint(method: "POST", path: "/v1/upload_videos")
        static let extractBaseFrames = Endpoint(method: "GET", path: "/v1/extract_base_frames")
        static let generateCompleteComic = Endpoint(method: "POST", path: "/v1/complete_comic")
        
        static func taskStatus(taskId: String) -> Endpoint {
            return Endpoint(method: "GET", path: "/v1/task_status/\(taskId)")
        }
        
        static func comicResult(taskId: String) -> Endpoint {
            return Endpoint(method: "GET", path: "/v1/comic_result/\(taskId)")
        }
        
        static func taskCancel(taskId: String) -> Endpoint {
            return Endpoint(method: "POST", path: "/v1/task_cancel/\(taskId)")
        }
    }
}

// MARK: - 设备ID生成
class DeviceIDGenerator {
    static func generateDeviceID() -> String {
        return UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    }
}

// MARK: - 时间计算器
class UploadTimingCalculator {
    static func calculateExpectedDuration(for videos: [URL]) -> TimeInterval {
        let baseTime: TimeInterval = 300 // 5分钟基础时间
        
        guard !videos.isEmpty else { return baseTime }
        
        // 根据视频总大小计算额外时间
        let totalSize = videos.reduce(0) { total, url in
            (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0 + total
        }
        
        let sizeInMB = Double(totalSize) / (1024 * 1024)
        let sizeMultiplier = min(max(sizeInMB / 50.0, 1.0), 10.0) // 限制上限
        
        // 多个视频时增加额外时间
        let videoMultiplier = min(Double(videos.count), 5.0)
        
        return baseTime * sizeMultiplier * (1 + (videoMultiplier - 1) * 0.5)
    }
}