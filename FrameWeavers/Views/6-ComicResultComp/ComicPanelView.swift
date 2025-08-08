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
        AsyncImageView(imageUrl: imageUrl)
            .aspectRatio(contentMode: .fit)
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color(hex: "#2F2617"), lineWidth: 2)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// 漫画叙述文本组件 - 仅负责展示叙述文本与占位
struct ComicNarrationTextView: View {
    let narration: String?
    let fontSize: CGFloat
    let lineSpacing: CGFloat
    let iconSpacing: CGFloat
    let iconSize: CGFloat

    var body: some View {
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
        let layout = LayoutCalculator(horizontalSizeClass: horizontalSizeClass, verticalSizeClass: verticalSizeClass).comicPanelLandscape
        return HStack(spacing: layout.spacing) {
            // 左侧：图片区域
            ComicImageSectionView(imageUrl: panel.imageUrl)
                .frame(maxWidth: .infinity)
                .padding(.leading, layout.horizontalPadding)

            // 右侧：文本区域
            landscapeTextSection
                .frame(width: layout.textAreaWidth)
                .padding(.trailing, layout.horizontalPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, layout.verticalPadding)
    }
    
    /// 竖屏布局 - 上下分栏
    var portraitLayout: some View {
        let layout = LayoutCalculator(horizontalSizeClass: horizontalSizeClass, verticalSizeClass: verticalSizeClass).comicPanelPortrait
        return VStack(spacing: layout.spacing) {
            Spacer(minLength: layout.topSpacing)
            
            // 上方：图片区域
            ComicImageSectionView(imageUrl: panel.imageUrl)
                .frame(maxWidth: .infinity)
                .frame(height: layout.imageHeight)
                .padding(.horizontal, layout.horizontalPadding)

            Spacer(minLength: layout.middleSpacing)
            
            // 下方：文本区域
            portraitTextSection
                .padding(.horizontal, layout.horizontalPadding)
            
            Spacer(minLength: layout.bottomSpacing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - UI Components
private extension ComicPanelView {
    // 图片区域已抽离为 `ComicImageSectionView`，保留此处空隙以便阅读

    /// 横屏文本区域组件
    var landscapeTextSection: some View {
        let layout = LayoutCalculator(horizontalSizeClass: horizontalSizeClass, verticalSizeClass: verticalSizeClass).comicPanelLandscape
        return VStack(spacing: 0) {
            // 文本内容区域 - "目"字上面的"口"
            ComicNarrationTextView(
                narration: panel.narration,
                fontSize: layout.fontSize,
                lineSpacing: layout.lineSpacing,
                iconSpacing: layout.iconSpacing,
                iconSize: layout.iconSize
            )
            .frame(maxWidth: .infinity)
            .frame(minHeight: layout.textContentMinHeight)
            .padding(.horizontal, layout.textHorizontalPadding)
            .padding(.top, layout.textTopPadding)

            // 页码区域 - "目"字下面的"口" - 改为VStack布局
            ComicPageFooterView(
                pageIndex: pageIndex,
                pageNumberFontSize: layout.pageNumberFontSize,
                isFontRestricted: true,
                areaHeight: layout.pageNumberAreaHeight,
                horizontalPadding: layout.textHorizontalPadding
            )
        }
    }
    
    /// 竖屏文本区域组件
    var portraitTextSection: some View {
        let layout = LayoutCalculator(horizontalSizeClass: horizontalSizeClass, verticalSizeClass: verticalSizeClass).comicPanelPortrait
        return VStack(spacing: layout.textSpacing) {
            // 文本内容区域
            ComicNarrationTextView(
                narration: panel.narration,
                fontSize: layout.fontSize,
                lineSpacing: layout.lineSpacing,
                iconSpacing: layout.iconSpacing,
                iconSize: layout.iconSize
            )
            .frame(maxWidth: .infinity)
            .frame(minHeight: layout.textContentMinHeight)
            .padding(.horizontal, layout.textHorizontalPadding)

            // 页码和水印区域
            ComicPageFooterView(
                pageIndex: pageIndex,
                pageNumberFontSize: layout.pageNumberFontSize,
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
    /// 是否为横屏模式
    var isLandscape: Bool {
        verticalSizeClass == .compact
    }
}
