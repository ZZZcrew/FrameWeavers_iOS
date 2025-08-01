import Foundation

// MARK: - 网络协议和服务

protocol NetworkServiceProtocol {
    func request(_ request: URLRequest) async throws -> Data
}

class NetworkService: NetworkServiceProtocol {
    func request(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidURL
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw NetworkError.uploadFailed(errorResponse.message ?? "Server error")
            } else {
                throw NetworkError.httpError(httpResponse.statusCode, nil)
            }
        }
        
        return data
    }
}

struct ErrorResponse: Codable {
    let success: Bool
    let message: String?
}
