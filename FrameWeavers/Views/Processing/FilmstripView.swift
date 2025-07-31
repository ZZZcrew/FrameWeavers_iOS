import SwiftUI

/// 胶片传送带视图 - 纯UI组件，遵循MVVM架构
struct FilmstripView: View {
    let displayImages: [DisplayImageData]
    let config: FilmstripConfiguration
    @State private var scrollOffset: CGFloat = 0

    init(displayImages: [DisplayImageData], config: FilmstripConfiguration = .default) {
        self.displayImages = displayImages
        self.config = config
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 胶片背景
                Color.black.opacity(0.8)

                // 滚动的图片传送带
                HStack(spacing: config.frameSpacing) {
                    // 重复图片以实现无限滚动
                    ForEach(0..<config.repeatCount, id: \.self) { index in
                        if !displayImages.isEmpty {
                            let imageIndex = index % displayImages.count
                            let displayImage = displayImages[imageIndex]

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
            }
        }
        .frame(height: 100)
        .clipped()
    }

    /// 启动传送带滚动动画
    private func startScrolling() {
        guard !displayImages.isEmpty else { return }

        let itemWidth = config.frameWidth + config.frameSpacing
        let totalWidth = itemWidth * CGFloat(displayImages.count)

        withAnimation(.linear(duration: Double(totalWidth / config.scrollSpeed)).repeatForever(autoreverses: false)) {
            scrollOffset = -totalWidth
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
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                loadingPlaceholder
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
        if let fallbackName = displayImage.fallbackName {
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

