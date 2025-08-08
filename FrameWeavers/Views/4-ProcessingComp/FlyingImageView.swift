import SwiftUI

/// 高级弧形飞跃动画组件 - 复刻HTML动画效果
struct FlyingImageView: View {
    let flyingImageInfo: FlyingImageInfo
    let namespace: Namespace.ID

    // MARK: - Animation State
    @State private var animationProgress: Double = 0.0

    // MARK: - Environment
    @Environment(\.responsiveProperties) private var responsive
    
    var body: some View {
        AsyncImageView(imageUrl: imageUrl, style: .minimal)
            .aspectRatio(contentMode: .fill)
            .frame(width: imageSize.width, height: imageSize.height)
            .clipShape(RoundedRectangle(cornerRadius: responsive.adaptiveCornerRadius))
            .scaleEffect(currentScale)
            .rotationEffect(.degrees(currentRotation))
            .opacity(currentOpacity)
            .matchedGeometryEffect(id: "filmstrip_\(flyingImageInfo.id)", in: namespace)
            .onAppear {
                startComplexAnimation()
            }
    }

    /// 获取图片URL字符串
    private var imageUrl: String {
        switch flyingImageInfo.imageSource {
        case .local(let name):
            return name
        case .remote(let url):
            return url?.absoluteString ?? ""
        }
    }

    // MARK: - Animation Properties

    /// 当前图片尺寸（带动画缩放）
    private var imageSize: CGSize {
        let baseWidth: CGFloat = responsive.isCompact ? 60 : 80
        let baseHeight: CGFloat = responsive.isCompact ? 80 : 100
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

    // MARK: - Animation Logic

    /// 开始复合动画效果
    private func startComplexAnimation() {
        // 使用HTML中的缓动函数：cubic-bezier(0.25, 0.46, 0.45, 0.94)
        withAnimation(.timingCurve(0.25, 0.46, 0.45, 0.94, duration: 0.4)) {
            animationProgress = 1.0
        }
    }
}
