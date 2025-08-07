import SwiftUI

/// 高级弧形飞跃动画组件 - 复刻HTML动画效果
struct FlyingImageView: View {
    let flyingImageInfo: FlyingImageInfo
    let namespace: Namespace.ID

    // MARK: - Animation State
    @State private var animationProgress: Double = 0.0

    // MARK: - Environment
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    // MARK: - Adaptive Properties
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    /// 响应式圆角半径
    private var adaptiveCornerRadius: CGFloat {
        if isLandscape {
            return isCompact ? 6 : 8
        } else {
            return isCompact ? 8 : 10
        }
    }
    
    var body: some View {
        Group {
            switch flyingImageInfo.imageSource {
            case .local(let name):
                localImageView(name: name)
            case .remote(let url):
                remoteImageView(url: url)
            }
        }
        .frame(width: imageSize.width, height: imageSize.height)
        .clipShape(RoundedRectangle(cornerRadius: adaptiveCornerRadius))
        .scaleEffect(currentScale)
        .rotationEffect(.degrees(currentRotation))
        .opacity(currentOpacity)
        .matchedGeometryEffect(id: "filmstrip_\(flyingImageInfo.id)", in: namespace)
        .onAppear {
            startComplexAnimation()
        }
    }

    // MARK: - Animation Properties

    /// 当前图片尺寸（带动画缩放）
    private var imageSize: CGSize {
        let baseWidth: CGFloat = isCompact ? 60 : 80
        let baseHeight: CGFloat = isCompact ? 80 : 100
        return CGSize(width: baseWidth, height: baseHeight)
    }

    /// 当前缩放比例
    private var currentScale: Double {
        1.0 - (0.25 * animationProgress) // 从1.0缩放到0.75
    }

    /// 当前旋转角度
    private var currentRotation: Double {
        sin(animationProgress * .pi) * 15 // 正弦波旋转，最大15度
    }

    /// 当前透明度
    private var currentOpacity: Double {
        1.0 - (0.2 * animationProgress) // 从1.0到0.8
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
    private var errorPlaceholder: some View {
        Rectangle()
            .fill(Color.orange.opacity(0.3))
            .overlay(
                Text("加载失败")
                    .font(.caption)
                    .dynamicTypeSize(...DynamicTypeSize.large)
                    .foregroundColor(.white)
            )
    }

    // MARK: - Animation Logic

    /// 开始复合动画效果
    private func startComplexAnimation() {
        // 使用HTML中的缓动函数：cubic-bezier(0.25, 0.46, 0.45, 0.94)
        withAnimation(.timingCurve(0.25, 0.46, 0.45, 0.94, duration: 0.4)) {
            animationProgress = 1.0
        }
    }
}
