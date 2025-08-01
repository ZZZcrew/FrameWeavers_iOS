import SwiftUI

// MARK: - UI相关的数据模型和PreferenceKeys

/// 用于在视图树中向上传递视图的Frame信息
struct FramePreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    
    static func reduce(value: inout [String : CGRect], nextValue: () -> [String : CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

/// 飞行图片的信息
struct FlyingImageInfo: Identifiable {
    let id: String
    let sourceFrame: CGRect
}

// MARK: - 显示图片相关数据模型

/// 显示图片数据 - 统一本地图片和远程图片的数据模型
struct DisplayImageData: Identifiable, Hashable {
    let id: String
    let imageSource: ImageSource
    let fallbackName: String?
    
    init(id: String, imageSource: ImageSource, fallbackName: String? = nil) {
        self.id = id
        self.imageSource = imageSource
        self.fallbackName = fallbackName
    }
}

/// 图片来源类型 - 区分本地图片和远程图片
enum ImageSource: Hashable {
    case local(name: String)
    case remote(url: URL?)
    
    /// 是否为本地图片
    var isLocal: Bool {
        switch self {
        case .local:
            return true
        case .remote:
            return false
        }
    }
    
    /// 是否为远程图片
    var isRemote: Bool {
        return !isLocal
    }
    
    /// 获取本地图片名称
    var localImageName: String? {
        switch self {
        case .local(let name):
            return name
        case .remote:
            return nil
        }
    }
    
    /// 获取远程图片URL
    var remoteURL: URL? {
        switch self {
        case .local:
            return nil
        case .remote(let url):
            return url
        }
    }
}

// MARK: - 胶片传送带配置
struct FilmstripConfiguration {
    let itemWidth: CGFloat
    let itemHeight: CGFloat
    let spacing: CGFloat
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    let animationDuration: Double

    // 兼容性属性
    var frameWidth: CGFloat { itemWidth }
    var frameHeight: CGFloat { itemHeight }
    var frameSpacing: CGFloat { spacing }
    let repeatCount: Int
    let scrollSpeed: CGFloat

    init(itemWidth: CGFloat, itemHeight: CGFloat, spacing: CGFloat, cornerRadius: CGFloat, shadowRadius: CGFloat, animationDuration: Double, repeatCount: Int = 10, scrollSpeed: CGFloat = 50.0) {
        self.itemWidth = itemWidth
        self.itemHeight = itemHeight
        self.spacing = spacing
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.animationDuration = animationDuration
        self.repeatCount = repeatCount
        self.scrollSpeed = scrollSpeed
    }

    static let `default` = FilmstripConfiguration(
        itemWidth: 80,
        itemHeight: 60,
        spacing: 12,
        cornerRadius: 8,
        shadowRadius: 4,
        animationDuration: 0.3,
        repeatCount: 10,
        scrollSpeed: 50.0
    )

    static let compact = FilmstripConfiguration(
        itemWidth: 60,
        itemHeight: 45,
        spacing: 8,
        cornerRadius: 6,
        shadowRadius: 2,
        animationDuration: 0.2,
        repeatCount: 8,
        scrollSpeed: 40.0
    )
}

// MARK: - 页面类型枚举
enum PageType {
    case comic(ComicPanel)
    case questions([String])
}

// MARK: - 导航状态
enum NavigationState {
    case welcome
    case styleSelection
    case processing
    case result
}

// MARK: - 处理状态UI模型
struct ProcessingUIState {
    let title: String
    let subtitle: String
    let progress: Double
    let isAnimating: Bool
    let showBaseFrames: Bool
    
    init(title: String, subtitle: String, progress: Double, isAnimating: Bool = true, showBaseFrames: Bool = false) {
        self.title = title
        self.subtitle = subtitle
        self.progress = progress
        self.isAnimating = isAnimating
        self.showBaseFrames = showBaseFrames
    }
}

// MARK: - 示例画册数据模型
struct SampleAlbum: Identifiable {
    let id: String
    let title: String
    let description: String
    let coverImage: String
    let comicResult: ComicResult?
}

// MARK: - 历史记录摘要
struct HistorySummary {
    let totalCount: Int
    let recentAlbums: [HistoryAlbum]
    let lastUpdateDate: Date?
    
    /// 是否有历史记录
    var hasHistory: Bool {
        totalCount > 0
    }
    
    /// 格式化的最后更新时间
    var formattedLastUpdateDate: String? {
        guard let lastUpdateDate = lastUpdateDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: lastUpdateDate)
    }
    
    /// 最近的标题列表
    var recentTitles: [String] {
        recentAlbums.map { $0.title }
    }
}
