import Foundation

// MARK: - 连环画结果模型
struct ComicResult: Codable, Identifiable {
    let comicId: String
    let deviceId: String
    let title: String
    let originalVideoTitle: String
    let creationDate: String
    let panelCount: Int
    let panels: [ComicPanel]
    let finalQuestions: [String]
    
    var id: String { comicId }
    
    init(comicId: String, deviceId: String, title: String, originalVideoTitle: String, creationDate: String, panelCount: Int, panels: [ComicPanel], finalQuestions: [String]) {
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

// MARK: - 连环画面板模型
struct ComicPanel: Codable, Identifiable {
    let id = UUID()
    let panelNumber: Int
    let imageUrl: String
    let narration: String?

    enum CodingKeys: String, CodingKey {
        case panelNumber, imageUrl, narration
    }
}

// MARK: - 连环画生成状态
enum ComicGenerationStatus {
    case idle                    // 空闲状态
    case extractingBaseFrames   // 提取基础帧
    case generatingComic        // 生成连环画
    case completed              // 完成
    case failed                 // 失败
    case cancelled              // 已取消

    var description: String {
        switch self {
        case .idle:
            return "待开始"
        case .extractingBaseFrames:
            return "提取基础帧中"
        case .generatingComic:
            return "生成连环画中"
        case .completed:
            return "已完成"
        case .failed:
            return "失败"
        case .cancelled:
            return "已取消"
        }
    }
}

// MARK: - 连环画进度结果
struct ComicProgressResult {
    let progress: Int
    let stage: String
    let message: String
    let shouldTryEarlyExtraction: Bool
    
    init(progress: Int, stage: String, message: String, shouldTryEarlyExtraction: Bool = false) {
        self.progress = progress
        self.stage = stage
        self.message = message
        self.shouldTryEarlyExtraction = shouldTryEarlyExtraction
    }
}

// MARK: - 故事风格枚举
enum StoryStyle: String, CaseIterable {
    case warmFairytale = "温馨童话"
    case adventureExploration = "冒险探索"
    case dailyLife = "日常生活"
    case fantasyMagic = "奇幻魔法"
    case scienceFiction = "科幻未来"
    case historicalLegend = "历史传说"
    case romanticLove = "浪漫爱情"
    case suspenseMystery = "悬疑推理"
    
    var description: String {
        switch self {
        case .warmFairytale:
            return "充满温暖和爱的童话故事，适合家庭分享"
        case .adventureExploration:
            return "刺激的冒险和探索之旅，充满未知的惊喜"
        case .dailyLife:
            return "记录生活中的美好瞬间，平凡中见真情"
        case .fantasyMagic:
            return "神奇的魔法世界，充满想象力的奇幻故事"
        case .scienceFiction:
            return "未来科技的奇妙世界，探索无限可能"
        case .historicalLegend:
            return "古老的传说和历史故事，传承文化记忆"
        case .romanticLove:
            return "浪漫的爱情故事，记录美好的情感时光"
        case .suspenseMystery:
            return "扣人心弦的悬疑故事，充满推理和解谜"
        }
    }
    
    var icon: String {
        switch self {
        case .warmFairytale:
            return "heart.fill"
        case .adventureExploration:
            return "mountain.2.fill"
        case .dailyLife:
            return "house.fill"
        case .fantasyMagic:
            return "sparkles"
        case .scienceFiction:
            return "rocket.fill"
        case .historicalLegend:
            return "book.fill"
        case .romanticLove:
            return "heart.circle.fill"
        case .suspenseMystery:
            return "magnifyingglass"
        }
    }
}

// MARK: - 连环画配置
struct ComicGenerationConfig {
    let storyStyle: StoryStyle
    let targetFrames: Int
    let frameInterval: Double
    let enableInteractiveQuestions: Bool
    let customPrompt: String?
    
    init(
        storyStyle: StoryStyle = .warmFairytale,
        targetFrames: Int = 8,
        frameInterval: Double = 1.0,
        enableInteractiveQuestions: Bool = true,
        customPrompt: String? = nil
    ) {
        self.storyStyle = storyStyle
        self.targetFrames = targetFrames
        self.frameInterval = frameInterval
        self.enableInteractiveQuestions = enableInteractiveQuestions
        self.customPrompt = customPrompt
    }
}

// MARK: - 连环画统计信息
struct ComicStatistics {
    let totalComics: Int
    let totalPanels: Int
    let averagePanelsPerComic: Double
    let mostUsedStyle: StoryStyle?
    let creationDateRange: (start: Date?, end: Date?)
    
    init(totalComics: Int, totalPanels: Int, averagePanelsPerComic: Double, mostUsedStyle: StoryStyle? = nil, creationDateRange: (start: Date?, end: Date?) = (nil, nil)) {
        self.totalComics = totalComics
        self.totalPanels = totalPanels
        self.averagePanelsPerComic = averagePanelsPerComic
        self.mostUsedStyle = mostUsedStyle
        self.creationDateRange = creationDateRange
    }
}
