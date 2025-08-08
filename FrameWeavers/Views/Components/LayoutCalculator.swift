import SwiftUI

/// 统一的布局计算器 - 管理ComicPanelView和QuestionsView的布局参数
/// 消除重复的布局计算逻辑，提供响应式布局支持
struct LayoutCalculator {
    // MARK: - Environment Properties
    private let horizontalSizeClass: UserInterfaceSizeClass?
    private let verticalSizeClass: UserInterfaceSizeClass?
    
    // MARK: - Initialization
    init(horizontalSizeClass: UserInterfaceSizeClass?, verticalSizeClass: UserInterfaceSizeClass?) {
        self.horizontalSizeClass = horizontalSizeClass
        self.verticalSizeClass = verticalSizeClass
    }
    
    // MARK: - Device Detection
    
    /// 是否为紧凑尺寸设备（iPhone）
    var isCompact: Bool {
        horizontalSizeClass == .compact
    }
    
    /// 是否为常规尺寸设备（iPad）
    var isRegular: Bool {
        horizontalSizeClass == .regular
    }
    
    /// 是否为横屏模式
    var isLandscape: Bool {
        verticalSizeClass == .compact
    }
    
    /// 是否为竖屏模式
    var isPortrait: Bool {
        verticalSizeClass != .compact
    }
    
    /// 设备类型
    var deviceType: DeviceType {
        switch (horizontalSizeClass, verticalSizeClass) {
        case (.regular, .regular):
            return .iPad
        case (.compact, _):
            return .iPhone
        default:
            return .iPhone
        }
    }
    
    // MARK: - ComicPanelView Layout Parameters
    
    /// ComicPanelView横屏布局参数
    var comicPanelLandscape: ComicPanelLandscapeLayout {
        ComicPanelLandscapeLayout(
            spacing: isRegular ? 40 : 30,
            horizontalPadding: isRegular ? 25 : 20,
            verticalPadding: 20,
            textAreaWidth: isRegular ? 280 : 240,
            textContentMinHeight: isRegular ? 220 : 200,
            textHorizontalPadding: isRegular ? 12 : 10,
            textTopPadding: isRegular ? 25 : 20,
            pageNumberAreaHeight: isRegular ? 70 : 60,
            pageNumberFontSize: isRegular ? 17 : 16,
            fontSize: isRegular ? 18 : 16,
            lineSpacing: isRegular ? 8 : 6,
            iconSpacing: isRegular ? 15 : 12,
            iconSize: isRegular ? 35 : 30
        )
    }
    
    /// ComicPanelView竖屏布局参数
    var comicPanelPortrait: ComicPanelPortraitLayout {
        ComicPanelPortraitLayout(
            spacing: isCompact ? 20 : 30,
            topSpacing: isCompact ? 20 : 30,
            middleSpacing: isCompact ? 20 : 30,
            bottomSpacing: isCompact ? 20 : 30,
            horizontalPadding: isCompact ? 20 : 30,
            imageHeight: isCompact ? 300 : 400,
            fontSize: isCompact ? 16 : 18,
            lineSpacing: isCompact ? 6 : 8,
            iconSpacing: isCompact ? 12 : 15,
            iconSize: isCompact ? 30 : 35,
            textContentMinHeight: isCompact ? 120 : 150,
            textHorizontalPadding: isCompact ? 16 : 20,
            pageNumberFontSize: isCompact ? 16 : 17,
            textSpacing: isCompact ? 16 : 20
        )
    }
    
    // MARK: - QuestionsView Layout Parameters
    
    /// QuestionsView布局参数（仅横屏）
    var questionsLayout: QuestionsLayout {
        QuestionsLayout(
            contentMinHeight: isRegular ? 220 : 200,
            contentHorizontalPadding: isRegular ? 50 : 40,
            contentTopPadding: isRegular ? 25 : 20,
            outerHorizontalPadding: isRegular ? 25 : 20,
            verticalPadding: isRegular ? 25 : 20,
            completionAreaHeight: isRegular ? 70 : 60,
            watermarkBottomPadding: isRegular ? 15 : 12,
            fontSize: isRegular ? 20 : 18,
            completionFontSize: isRegular ? 18 : 16,
            lineSpacing: isRegular ? 10 : 8
        )
    }
    
    // MARK: - Responsive Helpers
    
    /// 根据设备类型返回响应式值
    func responsiveValue<T>(iPhone: T, iPad: T) -> T {
        deviceType == .iPad ? iPad : iPhone
    }
    
    /// 根据横竖屏返回响应式值
    func orientationValue<T>(landscape: T, portrait: T) -> T {
        isLandscape ? landscape : portrait
    }
    
    /// 根据设备类型和横竖屏返回响应式值
    func responsiveOrientationValue<T>(iPhoneLandscape: T, iPhonePortrait: T, iPadLandscape: T, iPadPortrait: T) -> T {
        switch deviceType {
        case .iPhone:
            return isLandscape ? iPhoneLandscape : iPhonePortrait
        case .iPad:
            return isLandscape ? iPadLandscape : iPadPortrait
        }
    }
}

// MARK: - Supporting Types

/// 设备类型枚举
enum DeviceType {
    case iPhone
    case iPad
}

/// ComicPanelView横屏布局参数结构体
struct ComicPanelLandscapeLayout {
    let spacing: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let textAreaWidth: CGFloat
    let textContentMinHeight: CGFloat
    let textHorizontalPadding: CGFloat
    let textTopPadding: CGFloat
    let pageNumberAreaHeight: CGFloat
    let pageNumberFontSize: CGFloat
    let fontSize: CGFloat
    let lineSpacing: CGFloat
    let iconSpacing: CGFloat
    let iconSize: CGFloat
}

/// ComicPanelView竖屏布局参数结构体
struct ComicPanelPortraitLayout {
    let spacing: CGFloat
    let topSpacing: CGFloat
    let middleSpacing: CGFloat
    let bottomSpacing: CGFloat
    let horizontalPadding: CGFloat
    let imageHeight: CGFloat
    let fontSize: CGFloat
    let lineSpacing: CGFloat
    let iconSpacing: CGFloat
    let iconSize: CGFloat
    let textContentMinHeight: CGFloat
    let textHorizontalPadding: CGFloat
    let pageNumberFontSize: CGFloat
    let textSpacing: CGFloat
}

/// QuestionsView布局参数结构体
struct QuestionsLayout {
    let contentMinHeight: CGFloat
    let contentHorizontalPadding: CGFloat
    let contentTopPadding: CGFloat
    let outerHorizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let completionAreaHeight: CGFloat
    let watermarkBottomPadding: CGFloat
    let fontSize: CGFloat
    let completionFontSize: CGFloat
    let lineSpacing: CGFloat
}

// MARK: - Convenience Initializers
extension LayoutCalculator {
    /// 从SwiftUI环境中创建LayoutCalculator
    init(environment: EnvironmentValues) {
        self.init(
            horizontalSizeClass: environment.horizontalSizeClass,
            verticalSizeClass: environment.verticalSizeClass
        )
    }
}