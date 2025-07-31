import SwiftUI

/// 飞跃图片动画组件 - 纯UI组件，遵循单一职责原则
struct FlyingImageView: View {
    let flyingImageInfo: FlyingImageInfo?
    let namespace: Namespace.ID
    let baseFrames: [String: BaseFrameData]
    
    init(flyingImageInfo: FlyingImageInfo?,
         namespace: Namespace.ID,
         baseFrames: [String: BaseFrameData] = [:]) {
        self.flyingImageInfo = flyingImageInfo
        self.namespace = namespace
        self.baseFrames = baseFrames
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
        
        if let baseFrame = baseFrame, let url = baseFrame.thumbnailURL {
            // 使用基础帧数据的图片
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
            .frame(width: info.sourceFrame.width, height: info.sourceFrame.height)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .matchedGeometryEffect(id: info.id, in: namespace)
            .position(x: info.sourceFrame.midX, y: info.sourceFrame.midY)
            .transition(.identity)
        } else if baseFrame == nil {
            // 使用本地图片资源
            Image(info.id)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: info.sourceFrame.width, height: info.sourceFrame.height)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .matchedGeometryEffect(id: info.id, in: namespace)
                .position(x: info.sourceFrame.midX, y: info.sourceFrame.midY)
                .transition(.identity)
        } else {
            // 错误状态显示
            Rectangle()
                .fill(Color.orange.opacity(0.3))
                .overlay(
                    Text("URL无效")
                        .font(.caption)
                        .foregroundColor(.white)
                )
                .frame(width: info.sourceFrame.width, height: info.sourceFrame.height)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .matchedGeometryEffect(id: info.id, in: namespace)
                .position(x: info.sourceFrame.midX, y: info.sourceFrame.midY)
                .transition(.identity)
        }
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

#Preview {
    @Namespace var previewNamespace
    @State var mockFlyingInfo = FlyingImageInfo(
        id: "Image1",
        sourceFrame: CGRect(x: 100, y: 100, width: 120, height: 80)
    )
    
    return FlyingImageView(
        flyingImageInfo: mockFlyingInfo,
        namespace: previewNamespace,
        baseFrames: [:]
    )
    .frame(width: 400, height: 300)
    .background(Color.gray.opacity(0.1))
}
