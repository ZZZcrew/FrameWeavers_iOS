import SwiftUI

/// 单独的漫画页面视图组件 - 支持竖屏横屏响应式布局，符合MVVM架构和现代响应式设计规范
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

            // 根据横竖屏切换布局
            if isLandscape {
                landscapeLayout
            } else {
                portraitLayout
            }
        }
    }
}

// MARK: - Inline Components (嵌入以减少文件数量)

/// 漫画图片区组件 - 仅负责展示图片与边框
struct ComicImageSectionView: View {
    let imageUrl: String

    var body: some View {
        VStack {
            AsyncImageView(imageUrl: imageUrl)
                .aspectRatio(contentMode: .fit)
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color(hex: "#2F2617"), lineWidth: 2)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// 漫画叙述文本组件 - 仅负责展示叙述文本与占位
struct ComicNarrationTextView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let narration: String?
    let fontSize: CGFloat
    let lineSpacing: CGFloat
    let iconSpacing: CGFloat
    let iconSize: CGFloat

    var body: some View {
        VStack {
            if let narration = narration {
                Text(narration)
                    .font(.custom("STKaiti", size: fontSize))
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                    .foregroundColor(Color(hex: "#2F2617"))
                    .lineSpacing(lineSpacing)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            } else {
                VStack(spacing: iconSpacing) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: iconSize))
                        .foregroundColor(Color(hex: "#2F2617").opacity(0.5))
                    Text("暂无文本描述")
                        .font(.custom("STKaiti", size: fontSize))
                        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                        .foregroundColor(Color(hex: "#2F2617").opacity(0.5))
                }
            }
        }
    }
}

/// 漫画页脚组件 - 显示页码与水印
struct ComicPageFooterView: View {
    let pageIndex: Int
    let pageNumberFontSize: CGFloat
    let isFontRestricted: Bool
    let areaHeight: CGFloat?
    let horizontalPadding: CGFloat?

    var body: some View {
        VStack(spacing: 8) {
            Text("· \(pageIndex + 1) ·")
                .font(.custom("STKaiti", size: pageNumberFontSize))
                .dynamicTypeSize(isFontRestricted ? ...DynamicTypeSize.large : ...DynamicTypeSize.accessibility1)
                .foregroundColor(Color(hex: "#2F2617"))
            WatermarkLogoView()
        }
        .frame(maxWidth: .infinity)
        .if(areaHeight != nil) { view in
            view.frame(height: areaHeight!)
        }
        .if(horizontalPadding != nil) { view in
            view.padding(.horizontal, horizontalPadding!)
        }
    }
}


// MARK: - Layout Components
private extension ComicPanelView {
    /// 横屏布局 - 左右分栏
    var landscapeLayout: some View {
        HStack(spacing: landscapeSpacing) {
            // 左侧：图片区域
            ComicImageSectionView(imageUrl: panel.imageUrl)
                .frame(maxWidth: .infinity)
                .padding(.leading, landscapeHorizontalPadding)

            // 右侧：文本区域
            landscapeTextSection
                .frame(width: landscapeTextAreaWidth)
                .padding(.trailing, landscapeHorizontalPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, landscapeVerticalPadding)
    }
    
    /// 竖屏布局 - 上下分栏
    var portraitLayout: some View {
        VStack(spacing: portraitSpacing) {
            Spacer(minLength: portraitTopSpacing)
            
            // 上方：图片区域
            ComicImageSectionView(imageUrl: panel.imageUrl)
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
    }
}

// MARK: - UI Components
private extension ComicPanelView {
    // 图片区域已抽离为 `ComicImageSectionView`，保留此处空隙以便阅读

    /// 横屏文本区域组件
    var landscapeTextSection: some View {
        VStack(spacing: 0) {
            // 文本内容区域 - "目"字上面的"口"
            ComicNarrationTextView(
                narration: panel.narration,
                fontSize: landscapeFontSize,
                lineSpacing: landscapeLineSpacing,
                iconSpacing: landscapeIconSpacing,
                iconSize: landscapeIconSize
            )
            .frame(maxWidth: .infinity)
            .frame(minHeight: landscapeTextContentMinHeight)
            .padding(.horizontal, landscapeTextHorizontalPadding)
            .padding(.top, landscapeTextTopPadding)

            // 页码区域 - "目"字下面的"口" - 改为VStack布局
            ComicPageFooterView(
                pageIndex: pageIndex,
                pageNumberFontSize: landscapePageNumberFontSize,
                isFontRestricted: true,
                areaHeight: landscapePageNumberAreaHeight,
                horizontalPadding: landscapeTextHorizontalPadding
            )
        }
    }
    
    /// 竖屏文本区域组件
    var portraitTextSection: some View {
        VStack(spacing: portraitTextSpacing) {
            // 文本内容区域
            ComicNarrationTextView(
                narration: panel.narration,
                fontSize: portraitFontSize,
                lineSpacing: portraitLineSpacing,
                iconSpacing: portraitIconSpacing,
                iconSize: portraitIconSize
            )
            .frame(maxWidth: .infinity)
            .frame(minHeight: portraitTextContentMinHeight)
            .padding(.horizontal, portraitTextHorizontalPadding)

            // 页码和水印区域
            ComicPageFooterView(
                pageIndex: pageIndex,
                pageNumberFontSize: portraitPageNumberFontSize,
                isFontRestricted: true,
                areaHeight: nil,
                horizontalPadding: nil
            )
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
