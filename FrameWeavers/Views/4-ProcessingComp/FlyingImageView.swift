import SwiftUI

/// 飞跃图片动画组件 - 纯UI组件，遵循单一职责原则
struct FlyingImageView: View {
    let flyingImageInfo: FlyingImageInfo?
    let namespace: Namespace.ID
    let baseFrames: [String: BaseFrameData]

    // MARK: - Environment
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    init(flyingImageInfo: FlyingImageInfo?,
         namespace: Namespace.ID,
         baseFrames: [String: BaseFrameData] = [:]) {
        self.flyingImageInfo = flyingImageInfo
        self.namespace = namespace
        self.baseFrames = baseFrames
    }

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
            // 横屏时使用较小的圆角
            return isCompact ? 6 : 8
        } else {
            // 竖屏时使用标准圆角
            return isCompact ? 8 : 10
        }
    }

    /// 响应式尺寸缩放因子
    private var adaptiveScaleFactor: CGFloat {
        if isLandscape {
            // 横屏时稍微缩小以适应有限的垂直空间
            return isCompact ? 0.9 : 0.95
        } else {
            // 竖屏时使用标准尺寸
            return 1.0
        }
    }

    var body: some View {
        Group {
            if let info = flyingImageInfo {
                flyingImageContent(for: info)
            }
        }
    }
    
    /// 飞行图片内容视图
    @ViewBuilder
    private func flyingImageContent(for info: FlyingImageInfo) -> some View {
        let baseFrame = baseFrames[info.id]
        let adaptiveWidth = info.sourceFrame.width * adaptiveScaleFactor
        let adaptiveHeight = info.sourceFrame.height * adaptiveScaleFactor

        if let baseFrame = baseFrame, let url = baseFrame.thumbnailURL {
            // 使用基础帧数据的图片
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                loadingPlaceholder
            }
            .frame(width: adaptiveWidth, height: adaptiveHeight)
            .clipShape(RoundedRectangle(cornerRadius: adaptiveCornerRadius))
            .matchedGeometryEffect(id: info.id, in: namespace)
            .position(x: info.sourceFrame.midX, y: info.sourceFrame.midY)
            .transition(.identity)
        } else if baseFrame == nil {
            // 使用本地图片资源
            Image(info.id)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: adaptiveWidth, height: adaptiveHeight)
                .clipShape(RoundedRectangle(cornerRadius: adaptiveCornerRadius))
                .matchedGeometryEffect(id: info.id, in: namespace)
                .position(x: info.sourceFrame.midX, y: info.sourceFrame.midY)
                .transition(.identity)
        } else {
            // 错误状态显示
            errorPlaceholder(width: adaptiveWidth, height: adaptiveHeight, info: info)
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
    private func errorPlaceholder(width: CGFloat, height: CGFloat, info: FlyingImageInfo) -> some View {
        Rectangle()
            .fill(Color.orange.opacity(0.3))
            .overlay(
                Text("URL无效")
                    .font(.caption)
                    .dynamicTypeSize(...DynamicTypeSize.large)
                    .foregroundColor(.white)
            )
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: adaptiveCornerRadius))
            .matchedGeometryEffect(id: info.id, in: namespace)
            .position(x: info.sourceFrame.midX, y: info.sourceFrame.midY)
            .transition(.identity)
    }
}

/// 飞跃动画控制器 - 管理飞跃动画的触发和状态
struct FlyingImageController: View {
    @ObservedObject var galleryViewModel: ProcessingGalleryViewModel
    let namespace: Namespace.ID
    let frames: [String: CGRect]
    let isAnimationEnabled: Bool
    
    // 定时器
    private let jumpTimer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()
    
    init(galleryViewModel: ProcessingGalleryViewModel,
         namespace: Namespace.ID,
         frames: [String: CGRect],
         isAnimationEnabled: Bool = true) {
        self.galleryViewModel = galleryViewModel
        self.namespace = namespace
        self.frames = frames
        self.isAnimationEnabled = isAnimationEnabled
    }
    
    var body: some View {
        FlyingImageView(
            flyingImageInfo: galleryViewModel.flyingImageInfo,
            namespace: namespace,
            baseFrames: galleryViewModel.baseFrameDataMap
        )
        .onReceive(jumpTimer) { _ in
            if isAnimationEnabled {
                handleJumpTimer()
            }
        }
    }
    
    /// 处理跳跃动画定时器事件
    private func handleJumpTimer() {
        withAnimation(.easeInOut(duration: 1.2)) {
            galleryViewModel.triggerJumpAnimation(from: frames)
        }
    }
}
