import Foundation

// MARK: - 进度相关的核心模型

/// 进度轮询结果
struct ProgressResult {
    let status: String
    let progress: Int
    let message: String
    let stage: String?
    let shouldContinue: Bool
    let shouldExtractFrames: Bool
    let shouldTryEarlyExtraction: Bool
    
    init(
        status: String,
        progress: Int,
        message: String,
        stage: String? = nil,
        shouldContinue: Bool = true,
        shouldExtractFrames: Bool = false,
        shouldTryEarlyExtraction: Bool = false
    ) {
        self.status = status
        self.progress = progress
        self.message = message
        self.stage = stage
        self.shouldContinue = shouldContinue
        self.shouldExtractFrames = shouldExtractFrames
        self.shouldTryEarlyExtraction = shouldTryEarlyExtraction
    }
}

/// 任务状态枚举
enum TaskStatus: String, CaseIterable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .pending:
            return "等待中"
        case .processing:
            return "处理中"
        case .completed:
            return "已完成"
        case .failed:
            return "失败"
        case .cancelled:
            return "已取消"
        }
    }
    
    var isFinished: Bool {
        self == .completed || self == .failed || self == .cancelled
    }
    
    var isActive: Bool {
        self == .processing
    }
}

/// 处理阶段枚举
enum ProcessingStage: String, CaseIterable {
    case initializing = "initializing"
    case extractingKeyframes = "extracting_keyframes"
    case generatingStory = "generating_story"
    case stylizingFrames = "stylizing_frames"
    case completed = "completed"
    
    var displayName: String {
        switch self {
        case .initializing:
            return "初始化中"
        case .extractingKeyframes:
            return "正在提取关键帧"
        case .generatingStory:
            return "正在生成故事"
        case .stylizingFrames:
            return "正在风格化处理"
        case .completed:
            return "已完成"
        }
    }
    
    var progressWeight: Double {
        switch self {
        case .initializing:
            return 0.1
        case .extractingKeyframes:
            return 0.3
        case .generatingStory:
            return 0.4
        case .stylizingFrames:
            return 0.8
        case .completed:
            return 1.0
        }
    }
}

/// 任务信息
struct TaskInfo: Identifiable {
    let id: String
    let taskId: String
    let status: TaskStatus
    let progress: Int
    let stage: ProcessingStage?
    let message: String
    let createdAt: Date
    let updatedAt: Date
    
    init(
        taskId: String,
        status: TaskStatus = .pending,
        progress: Int = 0,
        stage: ProcessingStage? = nil,
        message: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = taskId
        self.taskId = taskId
        self.status = status
        self.progress = progress
        self.stage = stage
        self.message = message
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// 计算总体进度（0.0-1.0）
    var overallProgress: Double {
        let baseProgress = Double(progress) / 100.0
        let stageWeight = stage?.progressWeight ?? 0.0
        return min(max(baseProgress * stageWeight, 0.0), 1.0)
    }
    
    /// 是否可以取消
    var canCancel: Bool {
        status == .pending || status == .processing
    }
    
    /// 是否需要继续轮询
    var shouldContinuePolling: Bool {
        !status.isFinished
    }
}

/// 批量任务进度
struct BatchTaskProgress {
    let totalTasks: Int
    let completedTasks: Int
    let failedTasks: Int
    let activeTasks: Int
    let overallProgress: Double
    
    init(tasks: [TaskInfo]) {
        self.totalTasks = tasks.count
        self.completedTasks = tasks.filter { $0.status == .completed }.count
        self.failedTasks = tasks.filter { $0.status == .failed }.count
        self.activeTasks = tasks.filter { $0.status.isActive }.count
        
        if totalTasks > 0 {
            let totalProgress = tasks.reduce(0.0) { $0 + $1.overallProgress }
            self.overallProgress = totalProgress / Double(totalTasks)
        } else {
            self.overallProgress = 0.0
        }
    }
    
    var isCompleted: Bool {
        completedTasks == totalTasks
    }
    
    var hasFailures: Bool {
        failedTasks > 0
    }
    
    var successRate: Double {
        guard totalTasks > 0 else { return 0.0 }
        return Double(completedTasks) / Double(totalTasks)
    }
}
