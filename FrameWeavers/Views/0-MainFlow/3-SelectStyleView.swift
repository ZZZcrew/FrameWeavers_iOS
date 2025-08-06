import SwiftUI

/// 通用的风格选择视图组件 - 遵循现代SwiftUI响应式设计规范
struct StyleSelectionView<ViewModel: VideoUploadViewModel>: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ViewModel
    let nextView: AnyView

    // MARK: - Environment
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

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

    // MARK: - Body
    var body: some View {
        ZStack {
            // 背景图片
            Image("背景单色")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: adaptiveSpacing) {
                    Spacer(minLength: topSpacing)

                    titleText

                    Spacer(minLength: titleBottomSpacing)

                    quadrantSelectionArea

                    Spacer(minLength: buttonTopSpacing)

                    startGenerationButton

                    Spacer(minLength: bottomSpacing)
                }
                .padding(.horizontal, horizontalPadding)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            print("SelectStyleView: 已选择 \(viewModel.selectedVideos.count) 个视频")
            print("SelectStyleView: 初始状态 \(viewModel.uploadStatus.rawValue)")
        }
    }
}

// MARK: - Adaptive Properties
private extension StyleSelectionView {
    var isCompact: Bool {
        horizontalSizeClass == .compact || verticalSizeClass == .compact
    }

    var adaptiveSpacing: CGFloat { isCompact ? 16 : 24 }
    var topSpacing: CGFloat { isCompact ? 20 : 40 }
    var titleBottomSpacing: CGFloat { isCompact ? 30 : 50 }
    var buttonTopSpacing: CGFloat { isCompact ? 40 : 60 }
    var bottomSpacing: CGFloat { isCompact ? 20 : 40 }
    var horizontalPadding: CGFloat { isCompact ? 20 : 40 }
    var quadrantSize: CGFloat { isCompact ? 280 : 350 }
    var buttonMaxWidth: CGFloat { isCompact ? 220 : 250 }
}

// MARK: - UI Components
private extension StyleSelectionView {
    var titleText: some View {
        Text("· 选择故事风格 ·")
            .font(.custom("STKaiti", size: 18))
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            .fontWeight(.bold)
            .foregroundColor(Color(hex: "#2F2617"))
    }

    var quadrantSelectionArea: some View {
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
                        .font(.custom("WSQuanXing", size: isCompact ? 22 : 26))
                        .dynamicTypeSize(...DynamicTypeSize.large)
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
    }

    var startGenerationButton: some View {
        NavigationLink {
            nextView
        } label: {
            Image("开始生成")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: buttonMaxWidth)
                .frame(height: 50)
        }
        .disabled(viewModel.selectedStyle.isEmpty)
        .opacity(viewModel.selectedStyle.isEmpty ? 0.6 : 1.0)
    }
}

// MARK: - Business Logic
private extension StyleSelectionView {
    /// 计算按钮的响应式位置
    func calculateButtonPositions(for size: CGFloat) -> [(x: CGFloat, y: CGFloat)] {
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
