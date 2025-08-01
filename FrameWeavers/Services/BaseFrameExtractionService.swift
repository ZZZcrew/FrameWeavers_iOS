import Foundation

protocol BaseFrameExtractionServiceProtocol {
    func extractBaseFrames(taskId: String, interval: Double) async throws -> BaseFrameExtractionResponse
    func extractBaseFramesEarly(taskId: String, interval: Double) async -> BaseFrameExtractionResponse?
}

class BaseFrameExtractionService: BaseFrameExtractionServiceProtocol {
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }
    
    func extractBaseFrames(taskId: String, interval: Double) async throws -> BaseFrameExtractionResponse {
        let endpoint = NetworkConfig.Endpoint.extractBaseFrames(taskId: taskId, interval: interval)
        let request = createBaseFrameRequest(endpoint: endpoint)
        
        let data = try await networkService.request(request)
        let response = try JSONDecoder().decode(BaseFrameExtractionResponse.self, from: data)
        
        guard response.success else {
            throw BaseFrameExtractionError.serverError(response.message ?? "Failed to extract base frames")
        }
        
        return response
    }
    
    func extractBaseFramesEarly(taskId: String, interval: Double) async -> BaseFrameExtractionResponse? {
        do {
            let endpoint = NetworkConfig.Endpoint.extractBaseFrames(taskId: taskId, interval: interval)
            let request = createBaseFrameRequest(endpoint: endpoint)
            
            let data = try await networkService.request(request)
            let response = try JSONDecoder().decode(BaseFrameExtractionResponse.self, from: data)
            
            return response.success && !response.results.isEmpty ? response : nil
        } catch {
            print("ℹ️ 提前提取基础帧失败（可预期）: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func createBaseFrameRequest(endpoint: NetworkConfig.Endpoint) -> URLRequest {
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = endpoint.method
        request.timeoutInterval = NetworkConfig.requestTimeout
        
        return request
    }
}

// MARK: - 数据模型
struct BaseFrameExtractionResponse: Codable {
    let success: Bool
    let message: String
    let results: [BaseFrameResult]
}

struct BaseFrameResult: Codable {
    let videoName: String
    let baseFramesCount: Int
    let baseFramesPaths: [String]
}

enum BaseFrameExtractionError: Error, LocalizedError {
    case networkError(String)
    case serverError(String)
    case decodingError(Error)
    case noFramesAvailable
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "网络错误: \(message)"
        case .serverError(let message):
            return "服务器错误: \(message)"
        case .decodingError(let error):
            return "解析错误: \(error.localizedDescription)"
        case .noFramesAvailable:
            return "没有找到可用的基础帧"
        }
    }
}

// MARK: - 网络协议和服务
protocol NetworkServiceProtocol {
    func request(_ request: URLRequest) async throws -> Data
}

class NetworkService: NetworkServiceProtocol {
    func request(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw NetworkError.serverError(errorResponse.message ?? "Server error")
            } else {
                throw NetworkError.httpError(httpResponse.statusCode)
            }
        }
        
        return data
    }
}

struct ErrorResponse: Codable {
    let success: Bool
    let message: String?
}

enum NetworkError: Error {
    case invalidResponse
    case httpError(Int)
    case serverError(String)
}

// MARK: - 基础帧数据模型
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