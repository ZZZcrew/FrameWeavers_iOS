import SwiftUI

/// 单独的漫画页面视图组件 - 纯UI展示，符合MVVM架构和现代响应式设计规范
struct ComicPanelView: View {
    // MARK: - Environment
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    // MARK: - Properties
    let panel: ComicPanel
    let pageIndex: Int
    let totalPages: Int

    var body: some View {
        // 根据横竖屏切换布局
        if isLandscape {
            landscapeLayout
        } else {
            portraitLayout
        }
    }
}

// MARK: - Layout Components
private extension ComicPanelView {
    /// 横屏布局 - 左右分栏
    var landscapeLayout: some View {
        HStack(spacing: landscapeSpacing) {
            // 左侧：图片区域
            imageSection
                .frame(maxWidth: .infinity)
                .padding(.leading, landscapeHorizontalPadding)

            // 右侧：文本区域
            landscapeTextSection
                .frame(width: landscapeTextAreaWidth)
                .padding(.trailing, landscapeHorizontalPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped() // 防止内容超出边界
        .padding(.vertical, landscapeVerticalPadding)
    }
    
    /// 竖屏布局 - 上下分栏
    var portraitLayout: some View {
        VStack(spacing: portraitSpacing) {
            Spacer(minLength: portraitTopSpacing)
            
            // 上方：图片区域
            imageSection
                .frame(maxWidth: .infinity)
                .frame(height: portraitImageHeight)
                .padding(.horizontal, portraitHorizontalPadding)

            Spacer(minLength: portraitMiddleSpacing)
            
            // 下方：文本区域
            portraitTextSection
                .padding(.horizontal, portraitHorizontalPadding)
            
            Spacer(minLength: portraitBottomSpacing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped() // 防止内容超出边界
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
                .frame(maxWidth: .infinity)
                .clipped() // 防止图片超出边界
        }
    }

    /// 横屏文本区域组件
    var landscapeTextSection: some View {
        VStack(spacing: 0) {
            // 文本内容区域 - "目"字上面的"口"
            VStack {
                if let narration = panel.narration {
                    Text(narration)
                        .font(.custom("STKaiti", size: landscapeFontSize))
                        .dynamicTypeSize(...DynamicTypeSize.accessibility1) // 限制最大字体
                        .foregroundColor(Color(hex: "#2F2617"))
                        .lineSpacing(landscapeLineSpacing)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                } else {
                    // 如果没有叙述文本，显示占位符
                    VStack(spacing: landscapeIconSpacing) {
                        Image(systemName: "text.bubble")
                            .font(.system(size: landscapeIconSize))
                            .foregroundColor(Color(hex: "#2F2617").opacity(0.5))
                        Text("暂无文本描述")
                            .font(.custom("STKaiti", size: landscapeFontSize))
                            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                            .foregroundColor(Color(hex: "#2F2617").opacity(0.5))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: landscapeTextContentMinHeight)
            .padding(.horizontal, landscapeTextHorizontalPadding)
            .padding(.top, landscapeTextTopPadding)

            // 页码区域 - "目"字下面的"口" - 改为VStack布局
            VStack(spacing: 8) {                
                Text("· \(pageIndex + 1) ·")
                    .font(.custom("STKaiti", size: landscapePageNumberFontSize))
                    .dynamicTypeSize(...DynamicTypeSize.large) // 页码字体限制范围更小
                    .foregroundColor(Color(hex: "#2F2617"))
                
                // 水印logo
                WatermarkLogoView()
            }
            .frame(maxWidth: .infinity)
            .frame(height: landscapePageNumberAreaHeight)
            .padding(.horizontal, landscapeTextHorizontalPadding)
        }
    }
    
    /// 竖屏文本区域组件
    var portraitTextSection: some View {
        VStack(spacing: portraitTextSpacing) {
            // 文本内容区域
            VStack {
                if let narration = panel.narration {
                    Text(narration)
                        .font(.custom("STKaiti", size: portraitFontSize))
                        .dynamicTypeSize(...DynamicTypeSize.accessibility1) // 限制最大字体
                        .foregroundColor(Color(hex: "#2F2617"))
                        .lineSpacing(portraitLineSpacing)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                } else {
                    // 如果没有叙述文本，显示占位符
                    VStack(spacing: portraitIconSpacing) {
                        Image(systemName: "text.bubble")
                            .font(.system(size: portraitIconSize))
                            .foregroundColor(Color(hex: "#2F2617").opacity(0.5))
                        Text("暂无文本描述")
                            .font(.custom("STKaiti", size: portraitFontSize))
                            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                            .foregroundColor(Color(hex: "#2F2617").opacity(0.5))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: portraitTextContentMinHeight)
            .padding(.horizontal, portraitTextHorizontalPadding)

            // 页码和水印区域
            VStack(spacing: 8) {                
                Text("· \(pageIndex + 1) ·")
                    .font(.custom("STKaiti", size: portraitPageNumberFontSize))
                    .dynamicTypeSize(...DynamicTypeSize.large)
                    .foregroundColor(Color(hex: "#2F2617"))
                
                // 水印logo
                WatermarkLogoView()
            }
            .frame(maxWidth: .infinity)
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
    
    // MARK: - 横屏属性
    
    /// 横屏间距
    var landscapeSpacing: CGFloat {
        horizontalSizeClass == .regular ? 40 : 30
    }

    /// 横屏水平边距
    var landscapeHorizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 25 : 20
    }

    /// 横屏垂直边距
    var landscapeVerticalPadding: CGFloat {
        20
    }

    /// 横屏文本区域宽度
    var landscapeTextAreaWidth: CGFloat {
        horizontalSizeClass == .regular ? 280 : 240
    }

    /// 横屏文本内容最小高度
    var landscapeTextContentMinHeight: CGFloat {
        horizontalSizeClass == .regular ? 220 : 200
    }

    /// 横屏文本水平边距
    var landscapeTextHorizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 12 : 10
    }

    /// 横屏文本顶部边距
    var landscapeTextTopPadding: CGFloat {
        horizontalSizeClass == .regular ? 25 : 20
    }

    /// 横屏页码区域高度
    var landscapePageNumberAreaHeight: CGFloat {
        horizontalSizeClass == .regular ? 70 : 60
    }
    
    /// 横屏页码字体大小
    var landscapePageNumberFontSize: CGFloat {
        horizontalSizeClass == .regular ? 17 : 16
    }
    
    /// 横屏字体大小
    var landscapeFontSize: CGFloat {
        horizontalSizeClass == .regular ? 18 : 16
    }

    /// 横屏行间距
    var landscapeLineSpacing: CGFloat {
        horizontalSizeClass == .regular ? 8 : 6
    }

    /// 横屏图标间距
    var landscapeIconSpacing: CGFloat {
        horizontalSizeClass == .regular ? 15 : 12
    }

    /// 横屏图标大小
    var landscapeIconSize: CGFloat {
        horizontalSizeClass == .regular ? 35 : 30
    }
    
    // MARK: - 竖屏属性
    
    /// 竖屏间距
    var portraitSpacing: CGFloat {
        isCompact ? 20 : 30
    }

    /// 竖屏顶部间距
    var portraitTopSpacing: CGFloat {
        isCompact ? 20 : 30
    }
    
    /// 竖屏中间间距
    var portraitMiddleSpacing: CGFloat {
        isCompact ? 20 : 30
    }
    
    /// 竖屏底部间距
    var portraitBottomSpacing: CGFloat {
        isCompact ? 20 : 30
    }

    /// 竖屏水平边距
    var portraitHorizontalPadding: CGFloat {
        isCompact ? 20 : 30
    }

    /// 竖屏图片高度
    var portraitImageHeight: CGFloat {
        isCompact ? 300 : 400
    }

    /// 竖屏字体大小
    var portraitFontSize: CGFloat {
        isCompact ? 16 : 18
    }

    /// 竖屏行间距
    var portraitLineSpacing: CGFloat {
        isCompact ? 6 : 8
    }

    /// 竖屏图标间距
    var portraitIconSpacing: CGFloat {
        isCompact ? 12 : 15
    }

    /// 竖屏图标大小
    var portraitIconSize: CGFloat {
        isCompact ? 30 : 35
    }

    /// 竖屏文本内容最小高度
    var portraitTextContentMinHeight: CGFloat {
        isCompact ? 120 : 150
    }

    /// 竖屏文本水平边距
    var portraitTextHorizontalPadding: CGFloat {
        isCompact ? 16 : 20
    }

    /// 竖屏页码字体大小
    var portraitPageNumberFontSize: CGFloat {
        isCompact ? 16 : 17
    }
    
    /// 竖屏文本间距
    var portraitTextSpacing: CGFloat {
        isCompact ? 16 : 20
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
            
            // iPhone 16 Pro Max 竖屏测试
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
            .previewInterfaceOrientation(.portrait)
            .previewDisplayName("iPhone 16 Pro Max - 竖屏")
            
            // iPad Pro 竖屏测试
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
            .previewInterfaceOrientation(.portrait)
            .previewDisplayName("iPad Pro - 竖屏")
        }
    }
}
