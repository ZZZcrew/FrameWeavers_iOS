import SwiftUI
import UIKit

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
            forceLandscapeOrientation()
        }
        .onDisappear {
            // 恢复默认方向设置
            restoreDefaultOrientation()
        }
    }
    
    // MARK: - Private Methods
    /// 强制横屏
    private func forceLandscapeOrientation() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
        }
        
        // 设置状态栏方向
        UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
    }
    
    /// 恢复默认方向
    private func restoreDefaultOrientation() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .all))
        }
        
        // 恢复状态栏方向
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
    }
}

// MARK: - Layout Components
private extension QuestionsView {
    /// 横屏布局 - 居中对称布局
    var landscapeLayout: some View {
        VStack(spacing: 0) {
            // 问题内容区域
            questionContentSection
                .frame(maxWidth: .infinity)
                .frame(minHeight: landscapeContentMinHeight)
                .padding(.horizontal, landscapeContentHorizontalPadding)
                .padding(.top, landscapeContentTopPadding)

            // "完"字区域
            completionSection
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
        VStack {
            Text("· 完 ·")
                .font(.custom("STKaiti", size: adaptiveCompletionFontSize))
                .dynamicTypeSize(...DynamicTypeSize.large) // 完字字体限制范围更小
                .foregroundColor(Color(hex: "#2F2617"))
        }
    }
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

// MARK: - Preview
struct QuestionsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // iPhone 16 Pro Max 横屏测试
            QuestionsView(
                questions: [
                    "你觉得小明为什么会选择\"阳光\"这个名字给小狗？",
                    "如果你是小明，你会如何处理这只突然出现的流浪狗？",
                    "这个故事告诉我们什么关于友谊和善良的道理？"
                ],
                pageIndex: 3,
                totalPages: 4
            )
            .previewDevice("iPhone 16 Pro Max")
            .previewInterfaceOrientation(.landscapeLeft)
            .previewDisplayName("iPhone 16 Pro Max - 横屏")

            // iPad Pro 横屏测试
            QuestionsView(
                questions: [
                    "你觉得小明为什么会选择\"阳光\"这个名字给小狗？",
                    "如果你是小明，你会如何处理这只突然出现的流浪狗？",
                    "这个故事告诉我们什么关于友谊和善良的道理？"
                ],
                pageIndex: 3,
                totalPages: 4
            )
            .previewDevice("iPad Pro (12.9-inch) (6th generation)")
            .previewInterfaceOrientation(.landscapeLeft)
            .previewDisplayName("iPad Pro - 横屏")

            // 动态字体测试
            QuestionsView(
                questions: [
                    "你觉得小明为什么会选择\"阳光\"这个名字给小狗？",
                    "如果你是小明，你会如何处理这只突然出现的流浪狗？",
                    "这个故事告诉我们什么关于友谊和善良的道理？"
                ],
                pageIndex: 3,
                totalPages: 4
            )
            .previewDevice("iPhone 16 Pro Max")
            .previewInterfaceOrientation(.landscapeLeft)
            .environment(\.dynamicTypeSize, .accessibility1)
            .previewDisplayName("大字体测试")
            
            // iPhone 16 Pro Max 竖屏测试
            QuestionsView(
                questions: [
                    "你觉得小明为什么会选择\"阳光\"这个名字给小狗？",
                    "如果你是小明，你会如何处理这只突然出现的流浪狗？",
                    "这个故事告诉我们什么关于友谊和善良的道理？"
                ],
                pageIndex: 3,
                totalPages: 4
            )
            .previewDevice("iPhone 16 Pro Max")
            .previewInterfaceOrientation(.portrait)
            .previewDisplayName("iPhone 16 Pro Max - 竖屏")
            
            // iPad Pro 竖屏测试
            QuestionsView(
                questions: [
                    "你觉得小明为什么会选择\"阳光\"这个名字给小狗？",
                    "如果你是小明，你会如何处理这只突然出现的流浪狗？",
                    "这个故事告诉我们什么关于友谊和善良的道理？"
                ],
                pageIndex: 3,
                totalPages: 4
            )
            .previewDevice("iPad Pro (12.9-inch) (6th generation)")
            .previewInterfaceOrientation(.portrait)
            .previewDisplayName("iPad Pro - 竖屏")
        }
    }
}
