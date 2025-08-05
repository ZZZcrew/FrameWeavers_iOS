import SwiftUI

/// 胶片传送带视图 - 纯UI组件，遵循MVVM架构
struct FilmstripView: View {
    let baseFrames: [BaseFrameData]  // 直接使用基础帧数据
    let isExampleMode: Bool
    let config: FilmstripConfiguration
    let comicResult: ComicResult?  // 示例模式下的画册数据
    let customScrollSpeed: Double?  // 自定义滚动速度
    @State private var scrollOffset: CGFloat = 0

    init(baseFrames: [BaseFrameData] = [],
         isExampleMode: Bool = false,
         config: FilmstripConfiguration = .default,
         comicResult: ComicResult? = nil,
         customScrollSpeed: Double? = nil) {
        self.baseFrames = baseFrames
        self.isExampleMode = isExampleMode
        self.config = config
        self.comicResult = comicResult
        self.customScrollSpeed = customScrollSpeed
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
                // 胶片背景 - 限制高度并作为背景层
                Image("胶片")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 100)
                    .clipped()

                // 滚动的图片传送带
                HStack(spacing: config.frameSpacing) {
                    // 重复图片以实现无限滚动
                    ForEach(0..<config.repeatCount, id: \.self) { index in
                        let currentImages = actualDisplayImages
                        if !currentImages.isEmpty {
                            let imageIndex = index % currentImages.count
                            let displayImage = currentImages[imageIndex]

                            FilmFrameView(
                                displayImage: displayImage,
                                config: config
                            )
                        }
                    }
                }
                .offset(x: scrollOffset)
                .onAppear {
                    startScrolling()
                }
                .onChange(of: baseFrames) { _, _ in
                    // 当基础帧数据变化时，重新启动滚动动画
                    restartScrolling()
                }
            }
        }
        .frame(height: 100)
        .clipped()
    }

    /// 启动传送带滚动动画
    private func startScrolling() {
        let currentImages = actualDisplayImages
        guard !currentImages.isEmpty else { return }

        let itemWidth = config.frameWidth + config.frameSpacing
        let totalWidth = itemWidth * CGFloat(config.repeatCount)  // 与显示逻辑保持一致

        // 从右侧开始显示，让用户立即看到胶片内容
        let screenWidth = UIScreen.main.bounds.width
        scrollOffset = screenWidth - totalWidth  // 从屏幕右侧开始显示

        // 延迟启动动画，确保视图已完全渲染
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let effectiveSpeed = customScrollSpeed ?? config.scrollSpeed
            withAnimation(.linear(duration: Double(totalWidth / effectiveSpeed)).repeatForever(autoreverses: false)) {
                scrollOffset = screenWidth  // 向右滚动到屏幕右侧外完全消失
            }
        }
    }

    /// 重启滚动动画 - 当数据变化时调用
    private func restartScrolling() {
        // 停止当前动画，重置到右侧起始位置
        let currentImages = actualDisplayImages
        guard !currentImages.isEmpty else { return }

        let itemWidth = config.frameWidth + config.frameSpacing
        let totalWidth = itemWidth * CGFloat(config.repeatCount)  // 保持与startScrolling一致

        let screenWidth = UIScreen.main.bounds.width
        withAnimation(.linear(duration: 0)) {
            scrollOffset = screenWidth - totalWidth  // 重置到右侧起始位置
        }

        // 重新启动滚动
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            startScrolling()
        }
    }
}

// MARK: - 胶片帧视图组件

/// 胶片帧视图 - 纯UI组件，支持本地和远程图片
struct FilmFrameView: View {
    let displayImage: DisplayImageData
    let config: FilmstripConfiguration

    var body: some View {
        Group {
            switch displayImage.imageSource {
            case .local(let name):
                localImageView(name: name)

            case .remote(let url):
                remoteImageView(url: url)
            }
        }
        .frame(width: config.frameWidth, height: config.frameHeight)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    /// 本地图片视图
    @ViewBuilder
    private func localImageView(name: String) -> some View {
        Image(name)
            .resizable()
            .aspectRatio(contentMode: .fill)
    }

    /// 远程图片视图
    @ViewBuilder
    private func remoteImageView(url: URL?) -> some View {
        if let url = url {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure(_):
                    // 真实模式下加载失败时显示错误占位符，不使用fallback
                    errorPlaceholder
                case .empty:
                    loadingPlaceholder
                @unknown default:
                    loadingPlaceholder
                }
            }
        } else {
            errorPlaceholder
        }
    }

    /// 加载中占位符
    private var loadingPlaceholder: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                ProgressView()
                    .scaleEffect(0.5)
            )
    }

    /// 错误占位符
    @ViewBuilder
    private var errorPlaceholder: some View {
        // 真实模式下不使用fallback，只显示错误提示
        if displayImage.imageSource.isRemote {
            Rectangle()
                .fill(Color.red.opacity(0.3))
                .overlay(
                    Text("加载失败")
                        .font(.caption)
                        .foregroundColor(.white)
                )
        } else if let fallbackName = displayImage.fallbackName {
            // 示例模式下可以使用fallback
            Image(fallbackName)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Rectangle()
                .fill(Color.red.opacity(0.3))
                .overlay(
                    Text("加载失败")
                        .font(.caption)
                        .foregroundColor(.white)
                )
        }
    }
}

// MARK: - SwiftUI Preview
struct FilmstripView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Text("胶片传送带预览")
                .font(.title2)
                .padding()

            // 示例模式预览 - 使用默认配置
            FilmstripView(
                baseFrames: [],
                isExampleMode: true,
                config: .default,
                comicResult: nil,
                customScrollSpeed: 30.0
            )
            .background(Color.gray.opacity(0.1))

            // 等待状态预览
            FilmstripView(
                baseFrames: [],
                isExampleMode: false,
                config: .default,
                comicResult: nil,
                customScrollSpeed: 50.0
            )
            .background(Color.gray.opacity(0.1))

            Spacer()
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("胶片传送带")
    }
}

