import SwiftUI
import PhotosUI

/// 欢迎视图 - 遵循MVVM架构，使用现代SwiftUI响应式设计
struct WelcomeView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: VideoUploadViewModel
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showingSampleAlbums = false

    // MARK: - Environment
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: adaptiveSpacing) {
                Spacer(minLength: topSpacing)

                welcomeIcon

                welcomeTextContent

                videoSelectionButton

                hintText

                Spacer(minLength: bottomSpacing)
            }
            .padding(.horizontal, horizontalPadding)
            .frame(maxWidth: .infinity)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .fullScreenCover(isPresented: $showingSampleAlbums) {
            SampleAlbumsView()
        }
        .onChange(of: selectedItems) { _, newItems in
            handleVideoSelection(newItems)
        }
    }

}

// MARK: - Constants
private extension WelcomeView {
    static let welcomeText = """
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
}

// MARK: - Adaptive Properties
private extension WelcomeView {
    var isCompact: Bool {
        horizontalSizeClass == .compact || verticalSizeClass == .compact
    }

    var adaptiveSpacing: CGFloat {
        isCompact ? 16 : 24
    }

    var topSpacing: CGFloat {
        isCompact ? 20 : 40
    }

    var bottomSpacing: CGFloat {
        isCompact ? 20 : 40
    }

    var horizontalPadding: CGFloat {
        isCompact ? 20 : 40
    }

    var iconSize: CGFloat {
        isCompact ? 70 : 90
    }

    var buttonMaxWidth: CGFloat {
        isCompact ? 250 : 280
    }
}

// MARK: - UI Components
private extension WelcomeView {
    var welcomeIcon: some View {
        Image("icon-home")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: iconSize, height: iconSize)
            .shadow(radius: 10)
    }

    var welcomeTextContent: some View {
        TypewriterView(text: Self.welcomeText, typeSpeed: 0.08)
            .font(.custom("STKaiti", size: 18))
            .dynamicTypeSize(...DynamicTypeSize.accessibility1) // 限制最大字体
            .multilineTextAlignment(.center)
            .foregroundColor(Color(hex: "#2F2617"))
            .lineSpacing(4)
    }

    var videoSelectionButton: some View {
        PhotosPicker(
            selection: $selectedItems,
            maxSelectionCount: 9,
            matching: .videos,
            photoLibrary: .shared()
        ) {
            Image("button-import")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: buttonMaxWidth)
                .frame(height: 50)
        }
    }

    var hintText: some View {
        Text("选择有故事的片段效果更佳")
            .font(.custom("STKaiti", size: 12))
            .dynamicTypeSize(...DynamicTypeSize.large) // 限制字体大小
            .fontWeight(.bold)
            .multilineTextAlignment(.center)
            .foregroundColor(Color(hex: "#2F2617"))
            .tracking(1.2)
    }

    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("画册库") {
                showingSampleAlbums = true
            }
            .font(.custom("STKaiti", size: 16))
            .foregroundColor(Color(hex: "#855C23"))
        }
    }
}

// MARK: - Business Logic
private extension WelcomeView {
    func handleVideoSelection(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }

        Task {
            let videoURLs = await viewModel.processSelectedItems(items)
            await MainActor.run {
                viewModel.selectVideos(videoURLs)
                selectedItems = []
            }
        }
    }
}
