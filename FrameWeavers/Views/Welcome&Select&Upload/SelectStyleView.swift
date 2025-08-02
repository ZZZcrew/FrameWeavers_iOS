import SwiftUI

/// 通用的风格选择视图组件
struct StyleSelectionView<ViewModel: VideoUploadViewModel>: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ViewModel
    let nextView: AnyView

    // 定义故事风格
    private let storyStyles = [
        ("文艺哲学", "文 艺\n哲 学"),
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

                        // 响应式图钉位置计算
                        let pinPositions = calculatePinPositions(for: quadrantSize)
                        let pinIndex = viewModel.selectedStyle.isEmpty ? 1 : (storyStyles.firstIndex { $0.0 == viewModel.selectedStyle } ?? 1)

                        Image("图钉")
                            .resizable()
                            .scaledToFit()
                            .frame(width: quadrantSize * 0.15, height: quadrantSize * 0.15)
                            .position(x: pinPositions[pinIndex].x, y: pinPositions[pinIndex].y)

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
                                    .foregroundColor(viewModel.selectedStyle == styleKey ? Color(hex: "#FF6B35") : Color(hex: "#855C23"))
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
                            Image("button1")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: min(geometry.size.width * 0.6, 250),
                                       height: geometry.size.height * 0.055)

                            Text("开始生成")
                                .font(.custom("WSQuanXing", size: min(geometry.size.width * 0.055, 26)))
                                .fontWeight(.bold)
                                .foregroundColor(
                                    viewModel.selectedStyle.isEmpty ?
                                        Color(hex: "#CCCCCC") :
                                        Color(hex: "#855C23")
                                )
                                .minimumScaleFactor(0.8)
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

    /// 计算图钉的响应式位置
    private func calculatePinPositions(for size: CGFloat) -> [(x: CGFloat, y: CGFloat)] {
        let offsetX = size * 0.45  // 相对于中心的X偏移
        let offsetY = size * 0.1   // 相对于顶部的Y偏移
        let centerX = size * 0.5
        let centerY = size * 0.5

        return [
            // 往下移动：增大Y值或减小负Y偏移
            // 往上移动：减小Y值或增大负Y偏移
            // 往左移动：减小X值
            // 往右移动：增大X值

            // 左上象限 - 往下走一点点：减小 -size * 0.35 中的 0.35
            (x: centerX - offsetX + size * 0.43, y: centerY - offsetY - size * 0.3),

            // 右上象限 - 往下、往左走一点点：减小 offsetX，减小 -size * 0.35 中的 0.35
            (x: centerX + offsetX - size * 0.05, y: centerY - offsetY - size * 0.3),

            // 左下象限 - 往下走多一点点：增大 size * 0.2 中的 0.2
            (x: centerX - offsetX + size * 0.43, y: centerY + offsetY - size * 0.08),

            // 右下象限 - 往上、往左走一点点：减小 offsetX，减小 size * 0.2 中的 0.2
            (x: centerX + offsetX - size * 0.05, y: centerY + offsetY - size * 0.08)
        ]
    }

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
