import SwiftUI

/// 单独的漫画页面视图组件 - 横屏左右布局，符合MVVM架构和现代响应式设计规范
struct ComicPanelView: View {
    // MARK: - Environment
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    // MARK: - Properties
    let panel: ComicPanel
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
            HStack(spacing: adaptiveSpacing) {
                // 左侧：图片区域
                imageSection
                    .frame(maxWidth: .infinity)
                    .padding(.leading, horizontalPadding)

                // 右侧：文本区域
                textSection
                    .frame(width: textAreaWidth)
                    .padding(.trailing, horizontalPadding)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, verticalPadding)
        }
    }
}

// MARK: - UI Components
private extension ComicPanelView {
    /// 图片区域组件
    var imageSection: some View {
        VStack {
            AsyncImageView(imageUrl: panel.imageUrl)
                .aspectRatio(contentMode: .fit)
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color(hex: "#2F2617"), lineWidth: 2)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// 文本区域组件
    var textSection: some View {
        VStack(spacing: 0) {
            // 文本内容区域 - "目"字上面的"口"
            VStack {
                if let narration = panel.narration {
                    Text(narration)
                        .font(.custom("STKaiti", size: adaptiveFontSize))
                        .dynamicTypeSize(...DynamicTypeSize.accessibility1) // 限制最大字体
                        .foregroundColor(Color(hex: "#2F2617"))
                        .lineSpacing(adaptiveLineSpacing)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                } else {
                    // 如果没有叙述文本，显示占位符
                    VStack(spacing: adaptiveIconSpacing) {
                        Image(systemName: "text.bubble")
                            .font(.system(size: adaptiveIconSize))
                            .foregroundColor(Color(hex: "#2F2617").opacity(0.5))
                        Text("暂无文本描述")
                            .font(.custom("STKaiti", size: adaptiveFontSize))
                            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                            .foregroundColor(Color(hex: "#2F2617").opacity(0.5))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: textContentMinHeight)
            .padding(.horizontal, textHorizontalPadding)
            .padding(.top, textTopPadding)

            // 页码区域 - "目"字下面的"口" - 改为VStack布局
            VStack(spacing: 8) {                
                Text("· \(pageIndex + 1) ·")
                    .font(.custom("STKaiti", size: adaptivePageNumberFontSize))
                    .dynamicTypeSize(...DynamicTypeSize.large) // 页码字体限制范围更小
                    .foregroundColor(Color(hex: "#2F2617"))
                
                // 水印logo
                WatermarkLogoView()
            }
            .frame(maxWidth: .infinity)
            .frame(height: pageNumberAreaHeight)
            .padding(.horizontal, textHorizontalPadding)
        }
    }
}

// MARK: - Adaptive Properties
private extension ComicPanelView {
    /// 是否为紧凑尺寸设备
    var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    /// 是否为横屏模式
    var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    /// 自适应间距
    var adaptiveSpacing: CGFloat {
        horizontalSizeClass == .regular ? 40 : 30
    }

    /// 水平边距
    var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 25 : 20
    }

    /// 垂直边距
    var verticalPadding: CGFloat {
        20
    }

    /// 文本区域宽度 - 使用固定宽度替代geometry依赖
    var textAreaWidth: CGFloat {
        // 根据设备类型设置合理的固定宽度
        return horizontalSizeClass == .regular ? 280 : 240
    }

    /// 自适应字体大小
    var adaptiveFontSize: CGFloat {
        horizontalSizeClass == .regular ? 18 : 16
    }

    /// 页码字体大小
    var adaptivePageNumberFontSize: CGFloat {
        horizontalSizeClass == .regular ? 17 : 16
    }

    /// 自适应行间距
    var adaptiveLineSpacing: CGFloat {
        horizontalSizeClass == .regular ? 8 : 6
    }

    /// 图标间距
    var adaptiveIconSpacing: CGFloat {
        horizontalSizeClass == .regular ? 15 : 12
    }

    /// 图标大小
    var adaptiveIconSize: CGFloat {
        horizontalSizeClass == .regular ? 35 : 30
    }

    /// 文本内容最小高度
    var textContentMinHeight: CGFloat {
        horizontalSizeClass == .regular ? 220 : 200
    }

    /// 文本水平边距
    var textHorizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 12 : 10
    }

    /// 文本顶部边距
    var textTopPadding: CGFloat {
        horizontalSizeClass == .regular ? 25 : 20
    }

    /// 页码区域高度
    var pageNumberAreaHeight: CGFloat {
        horizontalSizeClass == .regular ? 70 : 60
    }
}

// MARK: - Preview
struct ComicPanelView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // iPhone 16 Pro Max 横屏测试
            ComicPanelView(
                panel: ComicPanel(
                    panelNumber: 1,
                    imageUrl: "Image1",
                    narration: "在一个阳光明媚的早晨，小明背着书包走在上学的路上。他哼着小曲，心情格外愉快，因为今天是他的生日。"
                ),
                pageIndex: 0,
                totalPages: 3
            )
            .previewDevice("iPhone 16 Pro Max")
            .previewInterfaceOrientation(.landscapeLeft)
            .previewDisplayName("iPhone 16 Pro Max - 横屏")

            // iPad Pro 横屏测试
            ComicPanelView(
                panel: ComicPanel(
                    panelNumber: 1,
                    imageUrl: "Image1",
                    narration: "在一个阳光明媚的早晨，小明背着书包走在上学的路上。他哼着小曲，心情格外愉快，因为今天是他的生日。"
                ),
                pageIndex: 0,
                totalPages: 3
            )
            .previewDevice("iPad Pro (12.9-inch) (6th generation)")
            .previewInterfaceOrientation(.landscapeLeft)
            .previewDisplayName("iPad Pro - 横屏")

            // 动态字体测试
            ComicPanelView(
                panel: ComicPanel(
                    panelNumber: 1,
                    imageUrl: "Image1",
                    narration: "在一个阳光明媚的早晨，小明背着书包走在上学的路上。他哼着小曲，心情格外愉快，因为今天是他的生日。"
                ),
                pageIndex: 0,
                totalPages: 3
            )
            .previewDevice("iPhone 16 Pro Max")
            .previewInterfaceOrientation(.landscapeLeft)
            .environment(\.dynamicTypeSize, .accessibility1)
            .previewDisplayName("大字体测试")
        }
    }
}
