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

/// 漫画页脚组件 - 显示页码
struct ComicPageFooterView: View {
    let pageIndex: Int
    let pageNumberFontSize: CGFloat
    let isFontRestricted: Bool
    let areaHeight: CGFloat?
    let horizontalPadding: CGFloat?

    var body: some View {
        Text("· \(pageIndex + 1) ·")
            .font(.custom("STKaiti", size: pageNumberFontSize))
            .dynamicTypeSize(isFontRestricted ? ...DynamicTypeSize.large : ...DynamicTypeSize.accessibility1)
            .foregroundColor(Color(hex: "#2F2617"))
            .if(horizontalPadding != nil) { view in
                view.padding(.horizontal, horizontalPadding!)
            }
    }
}


// MARK: - Layout Components
private extension ComicPanelView {
    /// 横屏布局 - 左右分栏（底部显示水印，随页面内容一起）
    var landscapeLayout: some View {
        let layout = LayoutCalculator(horizontalSizeClass: horizontalSizeClass, verticalSizeClass: verticalSizeClass).comicPanelLandscape
        return VStack(spacing: 0) {
            HStack(spacing: layout.spacing) {
                // 左侧：图片区域
                ComicImageSectionView(imageUrl: panel.imageUrl)
                    .frame(maxWidth: .infinity)
                    .padding(.leading, layout.horizontalPadding)

                // 右侧：文本区域
                textSection
                    .frame(width: layout.textAreaWidth)
                    .padding(.trailing, layout.horizontalPadding)
            }
            // .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, layout.verticalPadding)

            // 底部水印，使用与 QuestionsView 相似的 padding 值，随页面一起翻动
            WatermarkLogoView()
                .padding(.bottom, horizontalSizeClass == .regular ? 15 : 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            textSection
                .padding(.horizontal, layout.horizontalPadding)
            
            Spacer(minLength: layout.bottomSpacing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - UI Components
    /// 文本区域组件（横竖屏自适应）
    @ViewBuilder
    var textSection: some View {
        let calculator = LayoutCalculator(horizontalSizeClass: horizontalSizeClass, verticalSizeClass: verticalSizeClass)
        if isLandscape {
            let layout = calculator.comicPanelLandscape
            VStack(spacing: 0) {
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
        } else {
            let layout = calculator.comicPanelPortrait
            VStack(spacing: layout.textSpacing) {
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
    /// 是否为横屏模式
    var isLandscape: Bool {
        verticalSizeClass == .compact
    }
}