import Foundation

// MARK: - 连环画结果响应
struct ComicResultResponse: Codable {
    let success: Bool
    let message: String
    let taskId: String
    let results: ComicResults

    enum CodingKeys: String, CodingKey {
        case success = "success"
        case message = "message"
        case taskId = "task_id"
        case results = "results"
    }
}

// MARK: - 连环画结果集合
struct ComicResults: Codable {
    let successfulComics: [SuccessfulComic]
    let totalProcessed: Int
    let successCount: Int
    let failureCount: Int

    enum CodingKeys: String, CodingKey {
        case successfulComics = "successful_comics"
        case totalProcessed = "total_processed"
        case successCount = "success_count"
        case failureCount = "failure_count"
    }
}

// MARK: - 成功的连环画
struct SuccessfulComic: Codable {
    let videoName: String
    let success: Bool
    let comicData: ComicData

    enum CodingKeys: String, CodingKey {
        case videoName = "video_name"
        case success = "success"
        case comicData = "comic_data"
    }
}

// MARK: - 连环画数据
struct ComicData: Codable {
    let storyInfo: StoryInfo
    let pages: [ComicPage]
    let interactiveQuestions: [InteractiveQuestion]

    enum CodingKeys: String, CodingKey {
        case storyInfo = "story_info"
        case pages = "pages"
        case interactiveQuestions = "interactive_questions"
    }
}

// MARK: - 故事信息
struct StoryInfo: Codable {
    let overallTheme: String
    let title: String
    let summary: String
    let totalPages: Int
    let videoName: String
    let creationTime: String

    enum CodingKeys: String, CodingKey {
        case overallTheme = "overall_theme"
        case title = "title"
        case summary = "summary"
        case totalPages = "total_pages"
        case videoName = "video_name"
        case creationTime = "creation_time"
    }
}

// MARK: - 连环画页面
struct ComicPage: Codable {
    let pageIndex: Int
    let storyText: String
    let originalFramePath: String
    let styledFramePath: String
    let styledFilename: String
    let frameIndex: Int
    let styleApplied: Bool

    enum CodingKeys: String, CodingKey {
        case pageIndex = "page_index"
        case storyText = "story_text"
        case originalFramePath = "original_frame_path"
        case styledFramePath = "styled_frame_path"
        case styledFilename = "styled_filename"
        case frameIndex = "frame_index"
        case styleApplied = "style_applied"
    }
}

// MARK: - 交互问题
struct InteractiveQuestion: Codable {
    let questionId: String
    let question: String
    let intent: String  // 新增：对应后端的 intent 字段
    let questionType: String

    // 可选字段，因为后端可能不返回
    let options: [String]?
    let sceneDescription: String?

    enum CodingKeys: String, CodingKey {
        case questionId = "id"  // 修正：后端返回的是 "id" 而不是 "question_id"
        case question = "question"
        case intent = "intent"  // 新增：对应后端的 intent 字段
        case questionType = "type"  // 修正：后端返回的是 "type" 而不是 "question_type"
        case options = "options"
        case sceneDescription = "scene_description"
    }
}

// MARK: - Mock API响应模型（保持兼容）
struct UploadResponse: Codable {
    let success: Bool
    let data: UploadData?
    let error: APIError?
    let message: String?
}

struct UploadData: Codable {
    let mediaId: String
    let mediaType: String
    let uploadStatus: String
    let processingEstimate: String?
    let fileInfo: FileInfo
    let deviceInfo: DeviceInfo
    let uploadedAt: String
}

struct FileInfo: Codable {
    let fileName: String
    let fileSize: Int64
    let duration: Double
    let format: String
}

struct DeviceInfo: Codable {
    let deviceId: String
    let platform: String
    let osVersion: String
}
