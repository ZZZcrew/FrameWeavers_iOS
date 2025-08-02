import SwiftUI
import PhotosUI

/// 欢迎视图 - 遵循MVVM架构，只负责UI展示
struct WelcomeView: View {
    @ObservedObject var viewModel: VideoUploadViewModel
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showingSampleAlbums = false

    // MARK: - 性能优化：缓存和静态资源

    /// 缓存计算结果，避免重复计算（使用类来避免视图更新时的状态修改问题）
    @StateObject private var heightCache = TextHeightCache()

    /// 静态文本内容，避免重复创建
    private static let welcomeText = """
    有些故事，
    是你想和亲人分享的美好瞬间，
    可是视频给我们的时间太短，
    不足以停留在此刻。

    我们想说，我们想分享，
    此时此刻的故事。

    或许我们还想体验，
    和你的故事一致的风格，
    或许我们需要一个氛围，
    让你讲出属于你自己的故事。
    """

    /// 静态字体，避免重复创建
    private static let welcomeFont = UIFont(name: "STKaiti", size: 18) ?? UIFont.systemFont(ofSize: 18)

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // 顶部弹性空间 - 响应式调整
                DeviceAdaptation.responsiveSpacer(
                    geometry: geometry,
                    minHeight: 20,
                    maxHeight: 40
                )

                // 主图标区域 - 响应式尺寸
                Image("icon-home")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(
                        width: DeviceAdaptation.iconSize(
                            geometry: geometry,
                            baseRatio: 0.18,
                            maxSize: 90,
                            smallScreenRatio: 0.15
                        ),
                        height: DeviceAdaptation.iconSize(
                            geometry: geometry,
                            baseRatio: 0.18,
                            maxSize: 90,
                            smallScreenRatio: 0.15
                        )
                    )
                    .shadow(radius: 10)

                // 图标与文字间距 - 响应式调整
                DeviceAdaptation.responsiveSpacer(
                    geometry: geometry,
                    minHeight: 15,
                    maxHeight: 30,
                    smallScreenRatio: 0.5
                )

                // 文字内容区域 - 使用预计算高度，防止动画影响其他元素位置
                VStack {
                    TypewriterView(
                        text: Self.welcomeText,
                        typeSpeed: 0.08
                    )
                    .font(.custom("STKaiti", size: 18))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(hex: "#2F2617"))
                    .lineSpacing(DeviceAdaptation.lineSpacing(geometry: geometry))
                    .padding(.horizontal, geometry.size.width * 0.08)

                    Spacer() // 填充剩余空间
                }
                .frame(height: calculateTextContainerHeight(geometry: geometry)) // 动态计算高度

                // 文字与按钮间距 - 响应式调整
                DeviceAdaptation.responsiveSpacer(
                    geometry: geometry,
                    minHeight: 15,
                    maxHeight: 40,
                    smallScreenRatio: 0.4
                )

                // 主要操作按钮区域
                // 提前计算几何值，避免在闭包中捕获geometry
                let buttonWidth = min(geometry.size.width * 0.65, 280)
                let buttonHeight = min(geometry.size.width * 0.65 * 0.176, 50)
                let fontSize = min(geometry.size.width * 0.06, 24)

                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: 5,  // 最多选择5个视频
                    matching: .videos,
                    photoLibrary: .shared()
                ) {
                    ZStack {
                        Image("button-import")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: buttonWidth, height: buttonHeight)

                        Text("开启一段故事织造")
                            .font(.custom("WSQuanXing", size: fontSize))
                            .foregroundColor(Color(hex: "#855C23"))
                    }
                }

                // 按钮与提示文字间距 - 响应式调整
                DeviceAdaptation.responsiveSpacer(
                    geometry: geometry,
                    minHeight: 10,
                    maxHeight: 25,
                    smallScreenRatio: 0.5
                )

                // 底部提示文字
                Text("""
                最多上传5段3分钟内的视频
                选择有故事的片段效果更佳
                """)
                    .font(.custom("STKaiti", size: min(geometry.size.width * 0.03, 12)))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(hex: "#2F2617"))
                    .tracking(1.2)
                    .lineSpacing(DeviceAdaptation.lineSpacing(
                        geometry: geometry,
                        baseRatio: 0.012,
                        minSpacing: 2
                    ))
                    .padding(.horizontal, geometry.size.width * 0.1)

                // 底部弹性空间 - 响应式调整
                DeviceAdaptation.responsiveSpacer(
                    geometry: geometry,
                    minHeight: 20,
                    maxHeight: 40,
                    smallScreenRatio: 0.5
                )
            }
            .frame(minHeight: geometry.size.height) // 确保内容占满整个屏幕高度
            .frame(maxWidth: .infinity) // 确保内容水平居中
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingSampleAlbums = true
                }) {
                    Text("画册库")
                        .font(.custom("STKaiti", size: 16))
                        .foregroundColor(Color(hex: "#855C23"))
                }
            }
        }
        .fullScreenCover(isPresented: $showingSampleAlbums) {
            SampleAlbumsView()
        }
        .onChange(of: selectedItems) { _, newItems in
            handleVideoSelection(newItems)
        }
    }

    // MARK: - 私有方法

    /// 计算文字容器的合适高度（优化版本，带安全缓存）
    /// - Parameter geometry: 几何信息
    /// - Returns: 计算后的容器高度
    private func calculateTextContainerHeight(geometry: GeometryProxy) -> CGFloat {
        // 使用安全的缓存策略
        return heightCache.getHeight(for: geometry) { geometry in
            // 计算文字的实际高度
            let lineSpacing = DeviceAdaptation.lineSpacing(geometry: geometry)
            let horizontalPadding = geometry.size.width * 0.08 * 2 // 左右padding
            let availableWidth = geometry.size.width - horizontalPadding

            // 性能优化：复用段落样式对象
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = lineSpacing
            paragraphStyle.alignment = .center

            // 使用NSString计算文字高度
            let textHeight = Self.welcomeText.boundingRect(
                with: CGSize(width: availableWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [
                    .font: Self.welcomeFont,
                    .paragraphStyle: paragraphStyle
                ],
                context: nil
            ).height

            // 添加一些额外空间以确保完整显示，并根据设备调整
            let extraSpace: CGFloat = DeviceAdaptation.isSmallScreen(geometry) ? 40 : 60
            return textHeight + extraSpace
        }
    }

    /// 处理视频选择
    /// - Parameter items: 选择的PhotosPicker项目
    private func handleVideoSelection(_ items: [PhotosPickerItem]) {
        // 如果没有选择任何项目，直接返回
        guard !items.isEmpty else { return }

        Task {
            let videoURLs = await viewModel.processSelectedItems(items)
            await MainActor.run {
                viewModel.selectVideos(videoURLs)
                // 立即重置PhotosPicker的选择状态，这样按钮会变回"添加"
                selectedItems = []
            }
        }
    }
}

// MARK: - 性能优化：安全的文字高度缓存类

/// 文字高度缓存类，避免在视图更新时修改状态
class TextHeightCache: ObservableObject {
    private var cachedHeight: CGFloat = 0
    private var lastGeometrySize: CGSize = .zero
    private let tolerance: CGFloat = 1.0 // 几何尺寸变化容忍度

    /// 获取文字高度，带智能缓存
    /// - Parameters:
    ///   - geometry: 几何信息
    ///   - calculator: 高度计算闭包
    /// - Returns: 计算或缓存的高度
    func getHeight(for geometry: GeometryProxy, calculator: (GeometryProxy) -> CGFloat) -> CGFloat {
        let currentSize = geometry.size

        // 检查是否需要重新计算
        let needsRecalculation = cachedHeight <= 0 ||
            abs(currentSize.width - lastGeometrySize.width) > tolerance ||
            abs(currentSize.height - lastGeometrySize.height) > tolerance

        if needsRecalculation {
            // 重新计算并缓存
            cachedHeight = calculator(geometry)
            lastGeometrySize = currentSize
        }

        return cachedHeight
    }

    /// 清除缓存（在需要强制重新计算时使用）
    func clearCache() {
        cachedHeight = 0
        lastGeometrySize = .zero
    }
}
