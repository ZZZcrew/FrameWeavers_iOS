import Foundation
import Combine

protocol TaskStatusPollingServiceProtocol {
    func startPolling(taskId: String, interval: TimeInterval) -> AnyPublisher<TaskStatus, Error>
    func stopPolling()
    func getCurrentStatus(taskId: String) async throws -> TaskStatus
}

class TaskStatusPollingService: TaskStatusPollingServiceProtocol {
    private let networkService: NetworkServiceProtocol
    private var cancellable: AnyCancellable?
    private var timer: Timer?
    private let maxWaitTime: TimeInterval = 3000.0
    private let maxConsecutiveErrors = 10
    
    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }
    
    func startPolling(taskId: String, interval: TimeInterval = 2.0) -> AnyPublisher<TaskStatus, Error> {
        stopPolling()
        
        let startTime = Date()
        var consecutiveErrors = 0
        var lastProgress = -1
        
        return Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .tryMap { _ -> TaskStatus in
                if Date().timeIntervalSince(startTime) > self.maxWaitTime {
                    throw PollingError.timeout()
                }
                
                if consecutiveErrors >= self.maxConsecutiveErrors {
                    throw PollingError.tooManyErrors()
                }
                
                return try await self.getCurrentStatus(taskId: taskId)
            }
            .catch { error in
                if case let PollingError.statusFetchError(response) = error {
                    consecutiveErrors += 1
                    
                    // 对于高进度的情况，可能任务已经完成，尝试获取最终结果
                    if let response = response, response.progress >= 70 {
                        return Just(response)
                            .setFailureType(to: Error.self)
                            .eraseToAnyPublisher()
                    }
                }
                throw error
            }
            .filter { status in
                if let progress = status.progress {
                    let changed = progress != lastProgress
                    lastProgress = progress
                    return changed
                }
                return true
            }
            .eraseToAnyPublisher()
    }
    
    func stopPolling() {
        cancellable?.cancel()
        timer?.invalidate()
        timer = nil
    }
    
    func getCurrentStatus(taskId: String) async throws -> TaskStatus {
        let endpoint = NetworkConfig.Endpoint.taskStatus(taskId: taskId)
        let request = createStatusRequest(endpoint: endpoint)
        
        do {
            let data = try await networkService.request(request)
            let response = try JSONDecoder().decode(TaskStatusResponse.self, from: data)
            
            return TaskStatus(
                success: response.success,
                status: response.status,
                progress: response.progress,
                message: response.message,
                stage: response.stage,
                finalResult: response.finalResult
            )
        } catch {
            throw PollingError.statusFetchError(nil)
        }
    }
    
    private func createStatusRequest(endpoint: NetworkConfig.Endpoint) -> URLRequest {
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = endpoint.method
        request.timeoutInterval = NetworkConfig.requestTimeout
        
        return request
    }
}

// MARK: - 数据模型
struct TaskStatus {
    let success: Bool
    let status: String
    let progress: Int?
    let message: String?
    let stage: String?
    let finalResult: FinalResult?
    
    var isCompleted: Bool {
        return status == "complete_comic_completed"
    }
    
    var isFailed: Bool {
        return status == "complete_comic_failed" || status == "error"
    }
    
    var isProcessing: Bool {
        return status == "processing" || status == "uploaded"
    }
}

struct TaskStatusResponse: Codable {
    let success: Bool
    let status: String
    let progress: Int?
    let message: String?
    let stage: String?
    let finalResult: FinalResult?
    
    enum CodingKeys: String, CodingKey {
        case success, status, progress, message, stage
        case finalResult = "final_result"
    }
}

struct FinalResult: Codable {
    let title: String?
    let panels: [FinalPanel]?
    let questions: [String]?
    let original_video_title: String?
}

struct FinalPanel: Codable {
    let page: Int
    let baseImage: String
    let narration: String
    
    enum CodingKeys: String, CodingKey {
        case page
        case baseImage = "base_image"
        case narration
    }
}

enum PollingError: Error, LocalizedError {
    case timeout
    case tooManyErrors
    case statusFetchError(TaskStatusResponse?)
    
    var errorDescription: String? {
        switch self {
        case .timeout:
            return "任务处理超时，请稍后重试"
        case .tooManyErrors:
            return "连续出现错误，请稍后重试"
        case .statusFetchError(let response):
            if let response = response {
                return "获取任务状态失败: \(response.message ?? "Unknown error")"
            }
            return "无法获取任务状态"
        }
    }
}

extension NetworkConfig.Endpoint {
    static func taskStatus(taskId: String) -> NetworkConfig.Endpoint {
        return NetworkConfig.Endpoint(
            method: "GET",
            path: "/v1/task_status/\(taskId)"
        )
    }
    
    static func taskCancel(taskId: String) -> NetworkConfig.Endpoint {
        return NetworkConfig.Endpoint(
            method: "POST",
            path: "/v1/task_cancel/\(taskId)"
        )
    }
}

// MARK: - 进度管理器
class ProgressManager {
    static let shared = ProgressManager()
    
    private init() {}
    
    func convertToLocalizedDescription(stage: String) -> String {
        let stageDescriptions = [
            "initializing": "初始化中",
            "extracting_keyframes": "正在提取关键帧",
            "generating_story": "正在生成故事",
            "stylizing_frames": "正在风格化处理",
            "completed": "已完成"
        ]
        
        return stageDescriptions[stage] ?? stage
    }
    
    func calculateEstimatedTime(progress: Int, elapsedTime: TimeInterval) -> TimeInterval? {
        guard progress > 0 else { return nil }
        
        let estimatedTotalTime = elapsedTime * 100 / Double(progress)
        let remainingTime = estimatedTotalTime - elapsedTime
        
        return max(remainingTime, 0)
    }
}