import SwiftUI

/// 互动问题页面视图 - 符合MVVM架构和现代响应式设计规范
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
    }
}

private extension QuestionsView {
    /// 横屏布局
    var landscapeLayout: some View {
        let layout = LayoutCalculator(horizontalSizeClass: horizontalSizeClass, verticalSizeClass: .compact).questionsLayout
        return VStack(spacing: 0) {
            // 问题内容区域
            QuestionsContentTextView(questions: questions)
                .frame(maxWidth: .infinity)
                .frame(minHeight: layout.contentMinHeight)
                .padding(.horizontal, layout.contentHorizontalPadding)
                .padding(.top, layout.contentTopPadding)

            // "完"字区域
            QuestionsCompletionMarkView()
                .frame(maxWidth: .infinity)
                .frame(height: layout.completionAreaHeight)
                .padding(.horizontal, layout.contentHorizontalPadding)

            // 底部水印logo
            WatermarkLogoView()
                .padding(.bottom, layout.watermarkBottomPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, layout.outerHorizontalPadding)
        .padding(.vertical, layout.verticalPadding)
    }
}

/// 问题内容文本组件
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