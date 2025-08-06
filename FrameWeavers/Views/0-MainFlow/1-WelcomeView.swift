import SwiftUI
import PhotosUI

/// 欢迎视图 - 遵循MVVM架构，只负责UI展示
/// 采用简洁的单文件设计，通过 extension 组织代码结构
struct WelcomeView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: VideoUploadViewModel
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showingSampleAlbums = false
    @StateObject private var heightCache = TextHeightCache()

    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                topSpacer(geometry)
                welcomeIcon(geometry)
                iconTextSpacer(geometry)
                welcomeTextContent(geometry)
                textButtonSpacer(geometry)
                videoSelectionButton(geometry)
                buttonHintSpacer(geometry)
                hintText(geometry)
                bottomSpacer(geometry)
            }
            .frame(minHeight: geometry.size.height)
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

    static let welcomeFont = UIFont(name: "STKaiti", size: 18) ?? UIFont.systemFont(ofSize: 18)
}

// MARK: - UI Components
private extension WelcomeView {
    func topSpacer(_ geometry: GeometryProxy) -> some View {
        DeviceAdaptation.responsiveSpacer(
            geometry: geometry,
            minHeight: 20,
            maxHeight: 40
        )
    }

    func welcomeIcon(_ geometry: GeometryProxy) -> some View {
        let iconSize = DeviceAdaptation.iconSize(
            geometry: geometry,
            baseRatio: 0.18,
            maxSize: 90,
            smallScreenRatio: 0.15
        )

        return Image("icon-home")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: iconSize, height: iconSize)
            .shadow(radius: 10)
    }

    func iconTextSpacer(_ geometry: GeometryProxy) -> some View {
        DeviceAdaptation.responsiveSpacer(
            geometry: geometry,
            minHeight: 15,
            maxHeight: 30,
            smallScreenRatio: 0.5
        )
    }

    func welcomeTextContent(_ geometry: GeometryProxy) -> some View {
        VStack {
            TypewriterView(text: Self.welcomeText, typeSpeed: 0.08)
                .font(.custom("STKaiti", size: 18))
                .multilineTextAlignment(.center)
                .foregroundColor(Color(hex: "#2F2617"))
                .lineSpacing(DeviceAdaptation.lineSpacing(geometry: geometry))
                .padding(.horizontal, geometry.size.width * 0.08)

            Spacer()
        }
        .frame(height: calculateTextContainerHeight(geometry: geometry))
    }

    func textButtonSpacer(_ geometry: GeometryProxy) -> some View {
        DeviceAdaptation.responsiveSpacer(
            geometry: geometry,
            minHeight: 15,
            maxHeight: 40,
            smallScreenRatio: 0.4
        )
    }

    func videoSelectionButton(_ geometry: GeometryProxy) -> some View {
        let buttonWidth = min(geometry.size.width * 0.65, 280)
        let buttonHeight = min(geometry.size.width * 0.65 * 0.176, 50)

        return PhotosPicker(
            selection: $selectedItems,
            maxSelectionCount: 9,
            matching: .videos,
            photoLibrary: .shared()
        ) {
            Image("button-import")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: buttonWidth, height: buttonHeight)
        }
    }

    func buttonHintSpacer(_ geometry: GeometryProxy) -> some View {
        DeviceAdaptation.responsiveSpacer(
            geometry: geometry,
            minHeight: 10,
            maxHeight: 25,
            smallScreenRatio: 0.5
        )
    }

    func hintText(_ geometry: GeometryProxy) -> some View {
        Text("选择有故事的片段效果更佳")
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
    }

    func bottomSpacer(_ geometry: GeometryProxy) -> some View {
        DeviceAdaptation.responsiveSpacer(
            geometry: geometry,
            minHeight: 20,
            maxHeight: 40,
            smallScreenRatio: 0.5
        )
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
    func calculateTextContainerHeight(geometry: GeometryProxy) -> CGFloat {
        heightCache.getHeight(for: geometry) { geometry in
            let lineSpacing = DeviceAdaptation.lineSpacing(geometry: geometry)
            let horizontalPadding = geometry.size.width * 0.08 * 2
            let availableWidth = geometry.size.width - horizontalPadding

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = lineSpacing
            paragraphStyle.alignment = .center

            let textHeight = Self.welcomeText.boundingRect(
                with: CGSize(width: availableWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [
                    .font: Self.welcomeFont,
                    .paragraphStyle: paragraphStyle
                ],
                context: nil
            ).height

            let extraSpace: CGFloat = DeviceAdaptation.isSmallScreen(geometry) ? 40 : 60
            return textHeight + extraSpace
        }
    }

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
