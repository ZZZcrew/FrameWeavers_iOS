import SwiftUI

/// 简化的胶片传送带视图 - 实现无限水平滚动
struct FilmstripView: View {
    let imageNames: [String]
    @State private var scrollOffset: CGFloat = 0

    // 传送带参数
    private let frameWidth: CGFloat = 120
    private let frameHeight: CGFloat = 80
    private let frameSpacing: CGFloat = 10
    private let scrollSpeed: Double = 30 // 每秒移动30像素

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 胶片背景
                Color.black.opacity(0.8)

                // 滚动的图片传送带
                HStack(spacing: frameSpacing) {
                    // 重复图片以实现无限滚动
                    ForEach(0..<50) { index in // 足够多的图片确保无限滚动
                        let imageIndex = index % imageNames.count
                        let imageName = imageNames[imageIndex]

                        Image(imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: frameWidth, height: frameHeight)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
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
        let itemWidth = frameWidth + frameSpacing
        let totalWidth = itemWidth * CGFloat(imageNames.count)

        withAnimation(.linear(duration: Double(totalWidth / scrollSpeed)).repeatForever(autoreverses: false)) {
            scrollOffset = -totalWidth
        }
    }
}

