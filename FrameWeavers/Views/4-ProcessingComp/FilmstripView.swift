import SwiftUI

/// 胶片传送带视图 - 纯UI组件，遵循MVVM架构
struct FilmstripView: View {
    let baseFrames: [BaseFrameData]  // 直接使用基础帧数据
    let isExampleMode: Bool
    let config: FilmstripConfiguration
    let comicResult: ComicResult?  // 示例模式下的画册数据
    let customScrollSpeed: Double?  // 自定义滚动速度
    let onImageTapped: ((String) -> Void)?  // 图片点击回调
    let namespace: Namespace.ID  // 用于matchedGeometryEffect
    @State private var scrollOffset: CGFloat = 0

    // MARK: - Environment
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    init(baseFrames: [BaseFrameData] = [],
         isExampleMode: Bool = false,
         config: FilmstripConfiguration = .default,
         comicResult: ComicResult? = nil,
         customScrollSpeed: Double? = nil,
         onImageTapped: ((String) -> Void)? = nil,
         namespace: Namespace.ID) {
        self.baseFrames = baseFrames
        self.isExampleMode = isExampleMode
        self.config = config
        self.comicResult = comicResult
        self.customScrollSpeed = customScrollSpeed
        self.onImageTapped = onImageTapped
        self.namespace = namespace
    }

    // MARK: - Adaptive Properties
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    /// 响应式胶片高度
    private var adaptiveFilmstripHeight: CGFloat {
        if isLandscape {
            // 横屏时根据设备调整高度
            return horizontalSizeClass == .regular ? 80 : 70
        } else {
            // 竖屏时根据设备调整高度
            return isCompact ? 100 : 120
        }
    }

    /// 计算实际显示的图片数据
    private var actualDisplayImages: [DisplayImageData] {
        if isExampleMode {
            // 示例模式：优先使用画册的实际图片，否则使用默认本地图片
            if let comicResult = comicResult, !comicResult.panels.isEmpty {
                return comicResult.panels.map { panel in
                    DisplayImageData(
                        id: panel.imageUrl,
                        imageSource: .local(name: panel.imageUrl),
                        fallbackName: panel.imageUrl
                    )
                }
            } else {
                // 兜底：使用默认本地图片
                return ["Image1", "Image2", "Image3", "Image4"].map { name in
                    DisplayImageData(
                        id: name,
                        imageSource: .local(name: name),
                        fallbackName: name
                    )
                }
            }
        } else if !baseFrames.isEmpty {
            // 真实模式：使用基础帧数据
            return baseFrames.map { frame in
                DisplayImageData(
                    id: frame.id.uuidString,
                    imageSource: .remote(url: frame.thumbnailURL),
                    fallbackName: nil
                )
            }
        } else {
            // 等待状态：显示占位符
            return createLoadingPlaceholders()
        }
    }

    /// 创建加载占位符
    private func createLoadingPlaceholders() -> [DisplayImageData] {
        return (0..<4).map { index in
            DisplayImageData(
                id: "loading_placeholder_\(index)",
                imageSource: .local(name: "Image\(index + 1)"),
                fallbackName: "Image\(index + 1)"
            )
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 胶片背景 - 使用响应式高度
                Image("胶片")
                    .resizable(resizingMode: .tile)
                    .frame(height: adaptiveFilmstripHeight)
                    .clipped()

                // 滚动的图片传送带
                let currentImages = actualDisplayImages
                HStack(spacing: config.frameSpacing) {
                    // 重复图片以实现无限滚动
                    ForEach(0..<config.repeatCount, id: \.self) { index in
                        if !currentImages.isEmpty {
                            let imageIndex = index % currentImages.count
                            let displayImage = currentImages[imageIndex]

                            // 简单直接的方法：只有前N个图片使用matchedGeometry（N=原始图片数量）
                            // 这样确保每个图片ID只有一个源视图
                            let shouldUseGeometry = index < currentImages.count

                            FilmFrameView(
                                displayImage: displayImage,
                                config: config,
                                adaptiveHeight: adaptiveFilmstripHeight,
                                onTapped: onImageTapped,
                                namespace: namespace,
                                shouldUseMatchedGeometry: shouldUseGeometry
                            )
                        }
                    }
                }
                .offset(x: scrollOffset)
                .onAppear {
                    startScrolling(availableWidth: geometry.size.width)
                }
                .onChange(of: baseFrames) { _, _ in
                    // 当基础帧数据变化时，重新启动滚动动画
                    restartScrolling(availableWidth: geometry.size.width)
                }
            }
        }
        .frame(height: adaptiveFilmstripHeight)
        .clipped()
    }

    /// 启动传送带滚动动画
    private func startScrolling(availableWidth: CGFloat) {
        guard !actualDisplayImages.isEmpty else { return }

        let itemWidth = config.frameWidth + config.frameSpacing
        let totalWidth = itemWidth * CGFloat(config.repeatCount)

        // 从右侧开始显示，让用户立即看到胶片内容
        scrollOffset = availableWidth - totalWidth

        // 延迟启动动画，确保视图已完全渲染
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let effectiveSpeed = customScrollSpeed ?? config.scrollSpeed
            withAnimation(.linear(duration: Double(totalWidth / effectiveSpeed)).repeatForever(autoreverses: false)) {
                scrollOffset = availableWidth
            }
        }
    }

    /// 重启滚动动画 - 当数据变化时调用
    private func restartScrolling(availableWidth: CGFloat) {
        guard !actualDisplayImages.isEmpty else { return }

        // 停止当前动画并重置位置
        withAnimation(.linear(duration: 0)) {
            scrollOffset = availableWidth - (config.frameWidth + config.frameSpacing) * CGFloat(config.repeatCount)
        }

        // 重新启动滚动
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            startScrolling(availableWidth: availableWidth)
        }
    }
}

// MARK: - 胶片帧视图组件

/// 胶片帧视图 - 纯UI组件，支持本地和远程图片
struct FilmFrameView: View {
    let displayImage: DisplayImageData
    let config: FilmstripConfiguration
    let adaptiveHeight: CGFloat
    let onTapped: ((String) -> Void)?
    let namespace: Namespace.ID
    let shouldUseMatchedGeometry: Bool

    var body: some View {
        AsyncImageView(imageUrl: imageUrl, style: .minimal)
            .aspectRatio(contentMode: .fill)
            .frame(width: config.frameWidth, height: adaptiveHeight * 0.8) // 帧高度为胶片高度的80%
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .if(shouldUseMatchedGeometry) { view in
                view.matchedGeometryEffect(id: "filmstrip_\(displayImage.id)", in: namespace)
            }
            .onTapGesture {
                onTapped?(displayImage.id)
            }
    }

    /// 获取图片URL字符串
    private var imageUrl: String {
        switch displayImage.imageSource {
        case .local(let name):
            return name
        case .remote(let url):
            return url?.absoluteString ?? displayImage.fallbackName ?? ""
        }
    }


}
