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