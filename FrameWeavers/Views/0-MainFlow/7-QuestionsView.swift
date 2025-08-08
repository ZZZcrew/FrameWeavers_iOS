import SwiftUI

/// 互动问题页面视图 - 符合MVVM架构和现代响应式设计规范，强制横屏显示
struct QuestionsView: View {
    // MARK: - Environment
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    // MARK: - Properties
    let questions: [String]
    let pageIndex: Int
    let totalPages: Int

    var body: some View {
        ZStack {
            // 背景图片
            Image("背景单色")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // 强制横屏布局
            landscapeLayout
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        // MARK: - 沉浸式体验
        // 1. 隐藏系统覆盖层（如Home Indicator）
        .persistentSystemOverlays(.hidden)
        .onAppear {
            // 强制横屏
            OrientationManager.shared.forceLandscapeOrientation()
        }
        .onDisappear {
            // 恢复默认方向设置
            OrientationManager.shared.restoreDefaultOrientation()
        }
    }
}

// MARK: - Layout Components
private extension QuestionsView {
    /// 横屏布局 - 居中对称布局
    var landscapeLayout: some View {
        QuestionsLandscapeLayout(questions: questions)
    }
}

// MARK: - UI Components
private extension QuestionsView {
    /// 问题内容区域组件
    var questionContentSection: some View { QuestionsContentTextView(questions: questions) }

    /// 完成标记区域组件
    var completionSection: some View { QuestionsCompletionMarkView() }
}

// MARK: - Adaptive Properties
private extension QuestionsView {
    /// 是否为紧凑尺寸设备
    var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    /// 自适应字体大小（用于问题内容）
    var adaptiveFontSize: CGFloat {
        return horizontalSizeClass == .regular ? 20 : 18
    }

    /// 完成标记字体大小
    var adaptiveCompletionFontSize: CGFloat {
        return horizontalSizeClass == .regular ? 18 : 16
    }

    /// 自适应行间距
    var adaptiveLineSpacing: CGFloat {
        return horizontalSizeClass == .regular ? 10 : 8
    }
    
    // MARK: - 横屏属性
    
    /// 横屏内容最小高度
    var landscapeContentMinHeight: CGFloat {
        horizontalSizeClass == .regular ? 220 : 200
    }

    /// 横屏内容水平边距
    var landscapeContentHorizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 50 : 40
    }

    /// 横屏内容顶部边距
    var landscapeContentTopPadding: CGFloat {
        horizontalSizeClass == .regular ? 25 : 20
    }

    /// 横屏外层水平边距
    var landscapeOuterHorizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 25 : 20
    }

    /// 横屏垂直边距
    var landscapeVerticalPadding: CGFloat {
        horizontalSizeClass == .regular ? 25 : 20
    }

    /// 横屏完成区域高度
    var landscapeCompletionAreaHeight: CGFloat {
        horizontalSizeClass == .regular ? 70 : 60
    }
    
    /// 横屏水印底部边距
    var landscapeWatermarkBottomPadding: CGFloat {
        horizontalSizeClass == .regular ? 15 : 12
    }
    
}

// MARK: - Inline Components (embedded to reduce file count)
// 将三个独立组件内嵌到此文件，避免跨文件引用同时降低文件数量

/// 问题内容文本组件 - 直接嵌入同文件，避免跨文件引用
struct QuestionsContentTextView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let questions: [String]

    var body: some View {
        VStack {
            TypewriterView(
                text: questions.prefix(3).enumerated().map { index, question in
                    "\(index + 1). \(question)"
                }.joined(separator: "\n\n"),
                typeSpeed: 0.10,
                showCursor: false
            )
            .font(.custom("STKaiti", size: adaptiveFontSize))
            .dynamicTypeSize(...DynamicTypeSize.accessibility1) // 限制最大字体
            .foregroundColor(Color(hex: "#2F2617"))
            .lineSpacing(adaptiveLineSpacing)
            .multilineTextAlignment(.center)
            .lineLimit(nil)
        }
    }
}

private extension QuestionsContentTextView {
    var adaptiveFontSize: CGFloat {
        horizontalSizeClass == .regular ? 20 : 18
    }
    var adaptiveLineSpacing: CGFloat {
        horizontalSizeClass == .regular ? 10 : 8
    }
}

/// 完成标记组件
struct QuestionsCompletionMarkView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    var body: some View {
        VStack {
            Text("· 完 ·")
                .font(.custom("STKaiti", size: adaptiveCompletionFontSize))
                .dynamicTypeSize(...DynamicTypeSize.large)
                .foregroundColor(Color(hex: "#2F2617"))
        }
    }
    private var adaptiveCompletionFontSize: CGFloat {
        horizontalSizeClass == .regular ? 18 : 16
    }
}

/// 横屏问题页布局容器
struct QuestionsLandscapeLayout: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let questions: [String]
    var body: some View {
        VStack(spacing: 0) {
            // 问题内容区域
            QuestionsContentTextView(questions: questions)
                .frame(maxWidth: .infinity)
                .frame(minHeight: landscapeContentMinHeight)
                .padding(.horizontal, landscapeContentHorizontalPadding)
                .padding(.top, landscapeContentTopPadding)

            // "完"字区域
            QuestionsCompletionMarkView()
                .frame(maxWidth: .infinity)
                .frame(height: landscapeCompletionAreaHeight)
                .padding(.horizontal, landscapeContentHorizontalPadding)
            
            // 底部水印logo
            WatermarkLogoView()
                .padding(.bottom, landscapeWatermarkBottomPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, landscapeOuterHorizontalPadding)
        .padding(.vertical, landscapeVerticalPadding)
    }
    // 横屏自适应属性（与原实现保持一致）
    private var landscapeContentMinHeight: CGFloat { horizontalSizeClass == .regular ? 220 : 200 }
    private var landscapeContentHorizontalPadding: CGFloat { horizontalSizeClass == .regular ? 50 : 40 }
    private var landscapeContentTopPadding: CGFloat { horizontalSizeClass == .regular ? 25 : 20 }
    private var landscapeOuterHorizontalPadding: CGFloat { horizontalSizeClass == .regular ? 25 : 20 }
    private var landscapeVerticalPadding: CGFloat { horizontalSizeClass == .regular ? 25 : 20 }
    private var landscapeCompletionAreaHeight: CGFloat { horizontalSizeClass == .regular ? 70 : 60 }
    private var landscapeWatermarkBottomPadding: CGFloat { horizontalSizeClass == .regular ? 15 : 12 }
}
