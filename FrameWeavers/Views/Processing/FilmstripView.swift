import SwiftUI

/// 简化的胶片传送带视图 - 支持本地图片和后端基础帧
struct FilmstripView: View {
    let imageNames: [String]
    let baseFrames: [BaseFrameData] // 后端基础帧数据
    @State private var scrollOffset: CGFloat = 0

    // 传送带参数
    private let frameWidth: CGFloat = 120
    private let frameHeight: CGFloat = 80
    private let frameSpacing: CGFloat = 10
    private let scrollSpeed: Double = 30 // 每秒移动30像素

    // 计算实际使用的图片数据
    private var displayImages: [DisplayImageData] {
        if !baseFrames.isEmpty {
            // 使用后端基础帧数据
            return baseFrames.map { frame in
                DisplayImageData(
                    id: frame.id.uuidString,
                    imageSource: .remote(url: frame.thumbnailURL),
                    fallbackName: nil
                )
            }
        } else {
            // 使用本地图片
            return imageNames.map { name in
                DisplayImageData(
                    id: name,
                    imageSource: .local(name: name),
                    fallbackName: name
                )
            }
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 胶片背景
                Color.black.opacity(0.8)

                // 滚动的图片传送带
                HStack(spacing: frameSpacing) {
                    // 重复图片以实现无限滚动
                    ForEach(0..<50) { index in // 足够多的图片确保无限滚动
                        let imageIndex = index % displayImages.count
                        let displayImage = displayImages[imageIndex]

                        FilmFrameView(
                            displayImage: displayImage,
                            frameWidth: frameWidth,
                            frameHeight: frameHeight
                        )
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

        let itemWidth = frameWidth + frameSpacing
        let totalWidth = itemWidth * CGFloat(displayImages.count)

        withAnimation(.linear(duration: Double(totalWidth / scrollSpeed)).repeatForever(autoreverses: false)) {
            scrollOffset = -totalWidth
        }
    }
}

// MARK: - 支持数据结构

/// 显示图片数据 - 统一本地图片和远程图片
struct DisplayImageData: Identifiable {
    let id: String
    let imageSource: ImageSource
    let fallbackName: String?
}

/// 图片来源类型
enum ImageSource {
    case local(name: String)
    case remote(url: URL?)
}

/// 胶片帧视图 - 支持本地和远程图片
struct FilmFrameView: View {
    let displayImage: DisplayImageData
    let frameWidth: CGFloat
    let frameHeight: CGFloat

    var body: some View {
        Group {
            switch displayImage.imageSource {
            case .local(let name):
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fill)

            case .remote(let url):
                if let url = url {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.5)
                            )
                    }
                } else {
                    // URL无效时的回退处理
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
        }
        .frame(width: frameWidth, height: frameHeight)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

