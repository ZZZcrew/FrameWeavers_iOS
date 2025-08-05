import SwiftUI

/// 通用的风格选择视图组件
struct StyleSelectionView<ViewModel: VideoUploadViewModel>: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ViewModel
    let nextView: AnyView

    // 定义故事风格
    private let storyStyles = [
        ("赛博科幻", "赛 博\n科 幻"),
        ("童话想象", "童 话\n想 象"),
        ("悬念反转", "悬 念\n反 转"),
        ("生活散文", "生 活\n散 文")
    ]

    init(viewModel: ViewModel, nextView: AnyView) {
        self.viewModel = viewModel
        self.nextView = nextView
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景图片
                Image("背景单色")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                VStack(spacing: geometry.size.height * 0.03) {
                    Text("· 选择故事风格 ·")
                        .font(.custom("STKaiti", size: min(geometry.size.width * 0.04, 18)))
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "#2F2617"))
                        .padding(.bottom, geometry.size.height * 0.05)

                    // 响应式四象限选择区域
                    let quadrantSize = min(geometry.size.width * 0.85, geometry.size.height * 0.45)

                    ZStack {
                        Image("四象限")
                            .resizable()
                            .scaledToFit()
                            .frame(width: quadrantSize, height: quadrantSize)

                        // 使用动画图钉组件
                        let pinIndex = viewModel.selectedStyle.isEmpty ? 1 : (storyStyles.firstIndex { $0.0 == viewModel.selectedStyle } ?? 1)

                        AnimatedPinView(
                            currentIndex: pinIndex,
                            quadrantSize: quadrantSize,
                            isAnimating: !viewModel.selectedStyle.isEmpty
                        )

                        // 响应式按钮位置
                        let buttonPositions = calculateButtonPositions(for: quadrantSize)

                        ForEach(Array(storyStyles.enumerated()), id: \.offset) { index, style in
                            let styleKey = style.0
                            let styleText = style.1

                            Button(action: {
                                viewModel.selectStyle(styleKey)
                            }) {
                                Text(styleText)
                                    .font(.custom("WSQuanXing", size: min(geometry.size.width * 0.055, 26)))
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(hex: "#855C23"))
                                    .opacity(viewModel.selectedStyle == styleKey ? 1.0 : 0.3)
                                    .minimumScaleFactor(0.7)
                                    .lineLimit(2)
                            }
                            .position(x: buttonPositions[index].x, y: buttonPositions[index].y)
                        }
                    }
                    .frame(width: quadrantSize, height: quadrantSize)
                    .padding(.horizontal, geometry.size.width * 0.05)
                    .padding(.bottom, geometry.size.height * 0.08)

                    // 响应式开始生成按钮
                    NavigationLink {
                        nextView
                    } label: {
                        ZStack {
                            Image("开始生成")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: min(geometry.size.width * 0.6, 250),
                                       height: geometry.size.height * 0.055)
                        }
                    }
                    .disabled(viewModel.selectedStyle.isEmpty)
                    .opacity(viewModel.selectedStyle.isEmpty ? 0.6 : 1.0)

                    Spacer()
                }
                .padding(.horizontal, geometry.size.width * 0.05)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            print("SelectStyleView: 已选择 \(viewModel.selectedVideos.count) 个视频")
            print("SelectStyleView: 初始状态 \(viewModel.uploadStatus.rawValue)")
        }
    }

    // MARK: - 响应式位置计算方法



    /// 计算按钮的响应式位置
    private func calculateButtonPositions(for size: CGFloat) -> [(x: CGFloat, y: CGFloat)] {
        let offsetX = size * 0.225  // 相对于中心的X偏移
        let offsetY = size * 0.225  // 相对于中心的Y偏移
        let centerX = size * 0.5
        let centerY = size * 0.5

        return [
            (x: centerX - offsetX, y: centerY - offsetY), // 左上
            (x: centerX + offsetX, y: centerY - offsetY), // 右上
            (x: centerX - offsetX, y: centerY + offsetY), // 左下
            (x: centerX + offsetX, y: centerY + offsetY)  // 右下
        ]
    }
}

/// 真实上传模式的风格选择视图
struct RealSelectStyleView: View {
    @ObservedObject var viewModel: VideoUploadViewModel

    var body: some View {
        StyleSelectionView(
            viewModel: viewModel,
            nextView: AnyView(RealProcessingView(viewModel: viewModel))
        )
    }
}

/// 真实上传模式专用的处理视图
struct RealProcessingView: View {
    @ObservedObject var viewModel: VideoUploadViewModel

    var body: some View {
        ProcessingView(viewModel: viewModel)
            .onAppear {
                // 开始真实的上传和处理流程
                if viewModel.uploadStatus == .pending {
                    _ = viewModel.startGeneration()
                }
            }
    }
}

// MARK: - 保持向后兼容的别名
typealias SelectStyleView = RealSelectStyleView

// MARK: - SwiftUI Preview
struct SelectStyleView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = VideoUploadViewModel()
        viewModel.selectVideos([
            URL(string: "file:///mock/video1.mp4")!,
            URL(string: "file:///mock/video2.mp4")!
        ])
        return RealSelectStyleView(viewModel: viewModel)
    }
}
