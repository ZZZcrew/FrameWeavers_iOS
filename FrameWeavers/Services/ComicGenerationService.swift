import Foundation

class ComicGenerationService {
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }
    
    func generateCompleteComic(request: CompleteComicRequest) async throws -> ComicGenerationResponse {
        let endpoint = NetworkConfig.Endpoint.generateCompleteComic
        var requestConfig = createComicGenRequest(endpoint: endpoint)
        
        let requestBody = try JSONEncoder().encode(request)
        requestConfig.httpBody = requestBody
        requestConfig.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let data = try await networkService.request(requestConfig)
        let response = try JSONDecoder().decode(ComicGenerationResponse.self, from: data)
        
        guard response.success else {
            throw ComicGenerationError.serverError(response.message ?? "Failed to start comic generation")
        }
        
        return response
    }
    
    func fetchComicResult(taskId: String) async throws -> ComicResultResponse {
        let endpoint = NetworkConfig.Endpoint.comicResult(taskId: taskId)
        let request = createComicGenRequest(endpoint: endpoint)
        
        let data = try await networkService.request(request)
        return try JSONDecoder().decode(ComicResultResponse.self, from: data)
    }
    
    func convertToComicResult(from response: ComicResultResponse, taskId: String) -> ComicResult? {
        guard response.success else {
            return nil
        }
        
        let panels = response.data?.panels.map { panel in
            ComicPanel(
                panelNumber: panel.page,
                imageUrl: panel.baseImage,
                narration: panel.narration
            )
        } ?? []
        
        return ComicPanelData(
            comicId: taskId,
            deviceId: DeviceIDGenerator.generateDeviceID(),
            title: response.data?.title ?? "未命名故事",
            originalVideoTitle: response.data?.original_video_title ?? "",
            creationDate: ISO8601DateFormatter().string(from: Date()),
            panelCount: panels.count,
            panels: panels,
            finalQuestions: response.data?.questions ?? []
        )
    }
    
    private func createComicGenRequest(endpoint: NetworkConfig.Endpoint) -> URLRequest {
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = endpoint.method
        request.timeoutInterval = NetworkConfig.comicGenerationTimeout
        
        return request
    }
}

struct CompleteComicRequest: Codable {
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
    
    enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case videoPath = "video_path"
        case storyStyle = "story_style"
        case targetFrames, frameInterval, significanceWeight
        case qualityWeight, stylePrompt, imageSize, maxConcurrent
    }
}

struct ComicGenerationResponse: Codable {
    let success: Bool
    let message: String
}

struct ComicResultResponse: Codable {
    let success: Bool
    let message: String
    let data: ComicData?
}



struct ComicPanelData: Codable {
    let page: Int
    let baseImage: String
    let narration: String
    
    enum CodingKeys: String, CodingKey {
        case page
        case baseImage = "base_image"
        case narration
    }
}

final class ComicResultData: Codable {
    let comicId: String
    let deviceId: String
    let title: String
    let originalVideoTitle: String
    let creationDate: String
    let panelCount: Int
    let panels: [ComicPanel]
    let finalQuestions: [String]
    
    enum CodingKeys: String, CodingKey {
        case comicId = "comic_id"
        case deviceId = "device_id"
        case title
        case originalVideoTitle = "original_video_title"
        case creationDate = "creation_date"
        case panelCount = "panel_count"
        case panels
        case finalQuestions = "final_questions"
    }
    
    init(comicId: String, deviceId: String, title: String, originalVideoTitle: String,
         creationDate: String, panelCount: Int, panels: [ComicPanel], finalQuestions: [String]) {
        self.comicId = comicId
        self.deviceId = deviceId
        self.title = title
        self.originalVideoTitle = originalVideoTitle
        self.creationDate = creationDate
        self.panelCount = panelCount
        self.panels = panels
        self.finalQuestions = finalQuestions
    }
}

struct ComicPanel: Codable, Identifiable {
    let id = UUID()
    let panelNumber: Int
    let imageUrl: String
    let narration: String
    
    enum CodingKeys: String, CodingKey {
        case panelNumber = "panel_number"
        case imageUrl = "image_url"
        case narration
    }
}

enum ComicGenerationError: Error, LocalizedError {
    case networkError(String)
    case serverError(String)
    case decodingError(Error)
    case invalidResponse
    case noData
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "网络错误: \(message)"
        case .serverError(let message):
            return "服务器错误: \(message)"
        case .decodingError(let error):
            return "解析错误: \(error.localizedDescription)"
        case .invalidResponse:
            return "无效的响应"
        case .noData:
            return "没有收到数据"
        }
    }
}


