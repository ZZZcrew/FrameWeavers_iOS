import SwiftUI
import PhotosUI

/// 欢迎视图 - 遵循MVVM架构，只负责UI展示
struct WelcomeView: View {
    @ObservedObject var viewModel: VideoUploadViewModel
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showingSampleAlbums = false

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // 顶部弹性空间
                Spacer()

                // 主图标区域
                Image("icon-home")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: min(geometry.size.width * 0.25, 120),
                            height: min(geometry.size.width * 0.25, 120))
                    .shadow(radius: 10)

                // 图标与文字间距
                Spacer()
                    // .frame(height: 30)

                // 文字内容区域 - 让文字自适应高度
                TypewriterView(
                    text: """
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
                    """,
                    typeSpeed: 0.08
                )
                .font(.custom("STKaiti", size: min(geometry.size.width * 0.045, 18)))
                .multilineTextAlignment(.center)
                .foregroundColor(Color(hex: "#2F2617"))
                .lineSpacing(geometry.size.height * 0.012)
                .padding(.horizontal, geometry.size.width * 0.08)
                .fixedSize(horizontal: false, vertical: true) // 允许垂直方向自适应

                // 文字与按钮间距
                Spacer()
                    // .frame(height: 40)

                // 主要操作按钮区域
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
                            .frame(width: min(geometry.size.width * 0.65, 280),
                                    height: min(geometry.size.width * 0.65 * 0.176, 50))

                        Text("开启一段故事织造")
                            .font(.custom("WSQuanXing", size: min(geometry.size.width * 0.06, 24)))
                            .foregroundColor(Color(hex: "#855C23"))
                    }
                }

                // 按钮与提示文字间距
                Spacer()
                    // .frame(height: 25)

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
                    .lineSpacing(geometry.size.height * 0.012)
                    .padding(.horizontal, geometry.size.width * 0.1)

                // 底部弹性空间
                Spacer()
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
