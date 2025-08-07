import SwiftUI

/// 飞跃图片动画组件 - MVP版本，简单实现
struct FlyingImageView: View {
    let flyingImageInfo: FlyingImageInfo
    let namespace: Namespace.ID
    
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
        .frame(width: 60, height: 80) // 固定尺寸，简化实现
        .clipShape(RoundedRectangle(cornerRadius: adaptiveCornerRadius))
        .matchedGeometryEffect(id: "filmstrip_\(flyingImageInfo.id)", in: namespace)
        .transition(.identity)
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
}
