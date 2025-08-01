import Foundation

// MARK: - 上传状态枚举
enum UploadStatus: String {
    case pending = "待上传"
    case uploading = "上传中"
    case processing = "处理中"
    case completed = "已完成"
    case failed = "失败"
}

// MARK: - 视频上传响应模型
struct RealUploadResponse: Codable {
    let success: Bool
    let message: String
    let task_id: String?
    let uploaded_files: Int?
    let invalid_files: [String]?
    let video_path: String?  // 新增：后端返回的视频路径
}

// MARK: - 任务状态查询响应
struct TaskStatusResponse: Codable {
    let success: Bool
    let task_id: String
    let status: String
    let message: String
    let progress: Int
    let stage: String?  // 添加stage字段
    let created_at: String

    // 移除files字段，因为可能导致解析错误
    enum CodingKeys: String, CodingKey {
        case success, task_id, status, message, progress, stage, created_at
    }
}

// MARK: - 任务取消响应
struct TaskCancelResponse: Codable {
    let success: Bool
    let message: String
}

// MARK: - 基础帧提取响应模型
struct BaseFrameExtractionResponse: Codable {
    let success: Bool
    let message: String
    let taskId: String
    let results: [BaseFrameResult]

    enum CodingKeys: String, CodingKey {
        case success = "success"
        case message = "message"
        case taskId = "task_id"
        case results = "results"
    }
}

// MARK: - 基础帧结果
struct BaseFrameResult: Codable {
    let videoName: String
    let baseFramesCount: Int
    let baseFramesPaths: [String]
    let outputDir: String

    enum CodingKeys: String, CodingKey {
        case videoName = "video_name"
        case baseFramesCount = "base_frames_count"
        case baseFramesPaths = "base_frames_paths"
        case outputDir = "output_dir"
    }
}

// MARK: - 关键帧结果
struct KeyFrameResult: Codable {
    let videoName: String
    let baseFramesCount: Int
    let keyFramesCount: Int
    let keyFramesPaths: [String]
    let jsonFilePath: String
    let outputDir: String

    enum CodingKeys: String, CodingKey {
        case videoName = "video_name"
        case baseFramesCount = "base_frames_count"
        case keyFramesCount = "key_frames_count"
        case keyFramesPaths = "key_frames_paths"
        case jsonFilePath = "json_file_path"
        case outputDir = "output_dir"
    }
}

// MARK: - 关键帧提取响应
struct KeyFrameExtractionResponse: Codable {
    let success: Bool
    let message: String
    let taskId: String
    let results: [KeyFrameResult]

    enum CodingKeys: String, CodingKey {
        case success = "success"
        case message = "message"
        case taskId = "task_id"
        case results = "results"
    }
}

// MARK: - 完整连环画生成请求
struct CompleteComicRequest {
    let taskId: String
    let videoPath: String  // 必须：后端返回的视频路径
    let storyStyle: String  // 必须：故事风格关键词
    let targetFrames: Int
    let frameInterval: Double
    let significanceWeight: Double
    let qualityWeight: Double
    let stylePrompt: String
    let imageSize: String
    let maxRetries: Int
    let retryDelay: Double
    let maxConcurrent: Int

    init(
        taskId: String,
        videoPath: String,
        storyStyle: String,
        targetFrames: Int = 8,
        frameInterval: Double = 1.0,
        significanceWeight: Double = 0.7,
        qualityWeight: Double = 0.8,
        stylePrompt: String = "",
        imageSize: String = "1024x1024",
        maxRetries: Int = 3,
        retryDelay: Double = 2.0,
        maxConcurrent: Int = 3
    ) {
        self.taskId = taskId
        self.videoPath = videoPath
        self.storyStyle = storyStyle
        self.targetFrames = targetFrames
        self.frameInterval = frameInterval
        self.significanceWeight = significanceWeight
        self.qualityWeight = qualityWeight
        self.stylePrompt = stylePrompt
        self.imageSize = imageSize
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
        self.maxConcurrent = maxConcurrent
    }
}

// MARK: - 完整连环画生成响应
struct CompleteComicResponse: Codable {
    let success: Bool
    let message: String
    let taskId: String
    let status: String
    let progress: Int
    let stage: String

    enum CodingKeys: String, CodingKey {
        case success = "success"
        case message = "message"
        case taskId = "task_id"
        case status = "status"
        case progress = "progress"
        case stage = "stage"
    }
}

// MARK: - 多视频上传请求
struct MultiVideoUploadRequest {
    let videoURLs: [URL]
    let deviceId: String
}

// MARK: - API错误模型
struct APIError: Codable {
    let code: String
    let message: String
    let details: [String: String]?  // 简化为 String 类型
}

// MARK: - 上传进度
struct UploadProgress {
    let percentage: Double
    let uploadedBytes: Int64
    let totalBytes: Int64
    let speed: String?
    let estimatedTimeRemaining: String?
}
