import SwiftUI

/// 互动问题页面视图 - 符合MVVM架构和现代响应式设计规范，只负责UI展示
struct QuestionsView: View {
    // MARK: - Environment
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    // MARK: - Properties
    let questions: [String]
    let geometry: GeometryProxy
    let pageIndex: Int
    let totalPages: Int

    var body: some View {
        ZStack {
            // 背景图片
            Image("背景单色")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // 主要内容布局 - 移除嵌套GeometryReader，使用现代布局
            VStack(spacing: 0) {
                // 问题内容区域 - "目"字上面的"口"
                questionContentSection
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: contentMinHeight)
                    .padding(.horizontal, contentHorizontalPadding)
                    .padding(.top, contentTopPadding)

                // "完"字区域 - "目"字下面的"口"
                completionSection
                    .frame(maxWidth: .infinity)
                    .frame(height: completionAreaHeight)
                    .padding(.horizontal, contentHorizontalPadding)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, outerHorizontalPadding)
            .padding(.vertical, verticalPadding)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        // MARK: - 沉浸式体验
        // 1. 隐藏系统覆盖层（如Home Indicator）
        .persistentSystemOverlays(.hidden)
    }
}

// MARK: - UI Components
private extension QuestionsView {
    /// 问题内容区域组件
    var questionContentSection: some View {
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

    /// 完成标记区域组件
    var completionSection: some View {
        VStack(spacing: 8) {
            Text("· 完 ·")
                .font(.custom("STKaiti", size: adaptiveCompletionFontSize))
                .dynamicTypeSize(...DynamicTypeSize.large) // 完字字体限制范围更小
                .foregroundColor(Color(hex: "#2F2617"))
            
            // 水印logo
            WatermarkLogoView()
        }
    }
}

// MARK: - Adaptive Properties
private extension QuestionsView {
    /// 是否为紧凑尺寸设备
    var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    /// 是否为横屏模式
    var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    /// 自适应字体大小
    var adaptiveFontSize: CGFloat {
        horizontalSizeClass == .regular ? 20 : 18
    }

    /// 完成标记字体大小
    var adaptiveCompletionFontSize: CGFloat {
        horizontalSizeClass == .regular ? 18 : 16
    }

    /// 自适应行间距
    var adaptiveLineSpacing: CGFloat {
        horizontalSizeClass == .regular ? 10 : 8
    }

    /// 内容最小高度
    var contentMinHeight: CGFloat {
        horizontalSizeClass == .regular ? 220 : 200
    }

    /// 内容水平边距
    var contentHorizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 50 : 40
    }

    /// 内容顶部边距
    var contentTopPadding: CGFloat {
        horizontalSizeClass == .regular ? 25 : 20
    }

    /// 外层水平边距
    var outerHorizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 25 : 20
    }

    /// 垂直边距
    var verticalPadding: CGFloat {
        horizontalSizeClass == .regular ? 25 : 20
    }

    /// 完成区域高度
    var completionAreaHeight: CGFloat {
        horizontalSizeClass == .regular ? 70 : 60
    }
}

// MARK: - Preview
struct QuestionsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // iPhone 16 Pro Max 横屏测试
            GeometryReader { geometry in
                QuestionsView(
                    questions: [
                        "你觉得小明为什么会选择\"阳光\"这个名字给小狗？",
                        "如果你是小明，你会如何处理这只突然出现的流浪狗？",
                        "这个故事告诉我们什么关于友谊和善良的道理？"
                    ],
                    geometry: geometry,
                    pageIndex: 3,
                    totalPages: 4
                )
            }
            .previewDevice("iPhone 16 Pro Max")
            .previewInterfaceOrientation(.landscapeLeft)
            .previewDisplayName("iPhone 16 Pro Max - 横屏")

            // iPad Pro 横屏测试
            GeometryReader { geometry in
                QuestionsView(
                    questions: [
                        "你觉得小明为什么会选择\"阳光\"这个名字给小狗？",
                        "如果你是小明，你会如何处理这只突然出现的流浪狗？",
                        "这个故事告诉我们什么关于友谊和善良的道理？"
                    ],
                    geometry: geometry,
                    pageIndex: 3,
                    totalPages: 4
                )
            }
            .previewDevice("iPad Pro (12.9-inch) (6th generation)")
            .previewInterfaceOrientation(.landscapeLeft)
            .previewDisplayName("iPad Pro - 横屏")

            // 动态字体测试
            GeometryReader { geometry in
                QuestionsView(
                    questions: [
                        "你觉得小明为什么会选择\"阳光\"这个名字给小狗？",
                        "如果你是小明，你会如何处理这只突然出现的流浪狗？",
                        "这个故事告诉我们什么关于友谊和善良的道理？"
                    ],
                    geometry: geometry,
                    pageIndex: 3,
                    totalPages: 4
                )
            }
            .previewDevice("iPhone 16 Pro Max")
            .previewInterfaceOrientation(.landscapeLeft)
            .environment(\.dynamicTypeSize, .accessibility1)
            .previewDisplayName("大字体测试")
        }
    }
}
