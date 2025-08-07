import SwiftUI

/// 简化的照片堆叠视图组件 - 纯UI组件，遵循现代响应式设计
struct PhotoStackView: View {
    // MARK: - Environment
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    // MARK: - Properties
    let mainImageName: String
    let stackedImages: [String]
    let namespace: Namespace.ID
    let baseFrames: [String: BaseFrameData] // 基础帧数据映射

    // MARK: - Animation State
    @State private var newImageScale: Double = 0.0

    init(mainImageName: String,
         stackedImages: [String],
         namespace: Namespace.ID,
         baseFrames: [String: BaseFrameData] = [:]) {
        self.mainImageName = mainImageName
        self.stackedImages = stackedImages
        self.namespace = namespace
        self.baseFrames = baseFrames
    }

    var body: some View {
        ZStack {
            // 堆叠的背景图片
            ForEach(stackedImages.indices, id: \.self) { index in
                let imageName = stackedImages[index]
                let offset = CGFloat(index) * 3
                let rotation = Double.random(in: -8...8)
                let baseFrame = baseFrames[imageName]

                ZStack {
                    AsyncImageView(imageUrl: getImageUrl(for: imageName), style: .minimal)
                        .aspectRatio(contentMode: .fill)
                }
                .frame(width: cardWidth, height: cardHeight)
                .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius))
                .background(
                    RoundedRectangle(cornerRadius: cardCornerRadius).fill(.white)
                )
                .shadow(color: .black.opacity(0.1), radius: shadowRadius, y: 2)
                .rotationEffect(.degrees(rotation))
                .offset(x: offset, y: -offset)
                .zIndex(Double(index))
            }

            // 主图卡片
            ZStack {
                if !mainImageName.isEmpty {
                    AsyncImageView(imageUrl: mainImageUrl, style: .minimal)
                        .aspectRatio(contentMode: .fill)
                        .matchedGeometryEffect(id: "filmstrip_\(mainImageName)", in: namespace)
                }
            }
            .frame(width: cardWidth, height: cardHeight)
            .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius))
            .background(
                RoundedRectangle(cornerRadius: cardCornerRadius).fill(.white)
            )
            .shadow(color: .black.opacity(0.2), radius: mainShadowRadius, y: 5)
            .rotationEffect(.degrees(1))
            .scaleEffect(newImageScale)
            .zIndex(Double(stackedImages.count + 1))
            .onChange(of: mainImageName) { _, _ in
                // 当主图片变化时，触发弹性动画
                triggerBounceAnimation()
            }
            .onAppear {
                // 初始化时也触发动画
                newImageScale = 1.0
            }

            // 胶带
            Image("胶带")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .opacity(0.6)  // 60%不透明度
                .frame(width: tapeWidth, height: tapeHeight)
                .offset(y: tapeOffsetY)
                .zIndex(Double(stackedImages.count + 2))
        }
        .frame(height: containerHeight)
    }

    // MARK: - Helper Methods

    /// 获取主图片的URL字符串
    private var mainImageUrl: String {
        getImageUrl(for: mainImageName)
    }

    /// 获取指定图片的URL字符串
    private func getImageUrl(for imageName: String) -> String {
        if let baseFrame = baseFrames[imageName], let url = baseFrame.thumbnailURL {
            return url.absoluteString
        } else {
            return imageName // 本地图片名称
        }
    }

    // MARK: - Animation Methods

    /// 触发弹性动画效果
    private func triggerBounceAnimation() {
        // 先缩小到0
        newImageScale = 0.0

        // 然后用弹性动画放大到1.0，模拟HTML中的效果
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6, blendDuration: 0)) {
            newImageScale = 1.0
        }
    }
}

// MARK: - 响应式属性
extension PhotoStackView {

    /// 是否为紧凑尺寸
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    /// 是否为横屏模式 - 与ProcessingView保持一致
    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    // MARK: - 响应式尺寸属性
    private var cardWidth: CGFloat {
        if isLandscape {
            // 横屏时根据水平尺寸类调整
            return horizontalSizeClass == .regular ? 320 : 280
        } else {
            return isCompact ? 260 : 320  // 竖屏时根据设备调整
        }
    }

    private var cardHeight: CGFloat {
        if isLandscape {
            // 横屏时根据水平尺寸类调整
            return horizontalSizeClass == .regular ? 200 : 180
        } else {
            return isCompact ? 170 : 210  // 竖屏时根据设备调整
        }
    }

    private var containerHeight: CGFloat {
        if isLandscape {
            // 横屏时根据水平尺寸类调整
            return horizontalSizeClass == .regular ? 250 : 220
        } else {
            return isCompact ? 200 : 250  // 竖屏时根据设备调整
        }
    }

    private var cardCornerRadius: CGFloat { isCompact ? 6 : 8 }
    private var shadowRadius: CGFloat { isCompact ? 4 : 5 }
    private var mainShadowRadius: CGFloat { isCompact ? 8 : 10 }

    // MARK: - 胶带响应式属性
    private var tapeWidth: CGFloat {
        if isLandscape {
            return 220
        } else {
            return isCompact ? 180 : 200
        }
    }

    private var tapeHeight: CGFloat { isCompact ? 40 : 50 }

    private var tapeOffsetY: CGFloat {
        if isLandscape {
            return -90
        } else {
            return isCompact ? -85 : -100
        }
    }
}

// MARK: - Preview
struct PhotoStackView_Previews: PreviewProvider {
    @Namespace static var namespace

    static var previews: some View {
        VStack(spacing: 40) {
            // 预览1：基本状态
            PhotoStackView(
                mainImageName: "Image1",
                stackedImages: [],
                namespace: namespace,
                baseFrames: [:]
            )
            .previewDisplayName("基本状态")

            // 预览2：有堆叠图片
            PhotoStackView(
                mainImageName: "Image2",
                stackedImages: ["Image1", "Image3"],
                namespace: namespace,
                baseFrames: [:]
            )
            .previewDisplayName("有堆叠图片")
        }
        .padding()
        .background(Color(red: 0.91, green: 0.88, blue: 0.83))
        .previewLayout(.sizeThatFits)
    }
}