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
            ZStack {
                Image("背景单色")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                VStack(spacing: 30) {
                    Text("· 选择故事风格 ·")
                        .font(.custom("STKaiti", size: 16))
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "#2F2617"))
                        .padding(.bottom, 50)
                    
                    ZStack {
                        Image("四象限")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 400, height: 400)
                        
                        // 图钉图标 - 初始在右上角，根据选中位置移动
                        let pinPositions = [
                            (x: 180, y: 40),   // 左上象限右上角
                            (x: 360, y: 40),   // 右上象限右上角（初始位置）
                            (x: 180, y: 220),  // 左下象限右上角
                            (x: 360, y: 220)   // 右下象限右上角
                        ]
                        
                        let pinIndex = viewModel.selectedStyle.isEmpty ? 1 : (storyStyles.firstIndex { $0.0 == viewModel.selectedStyle } ?? 1)
                        Image("图钉")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .position(x: CGFloat(pinPositions[pinIndex].x), y: CGFloat(pinPositions[pinIndex].y))
                        
                        // 四个象限的风格选择按钮
                        let positions = [
                            (x: 110, y: 110),  // 左上
                            (x: 290, y: 110),  // 右上
                            (x: 110, y: 290),  // 左下
                            (x: 290, y: 290)   // 右下
                        ]

                        ForEach(Array(storyStyles.enumerated()), id: \.offset) { index, style in
                            let styleKey = style.0
                            let styleText = style.1

                            Button(action: {
                                viewModel.selectStyle(styleKey)
                            }) {
                                Text(styleText)
                                    .font(.custom("WSQuanXing", size: 24))
                                    .fontWeight(.bold)
                                    .foregroundColor(viewModel.selectedStyle == styleKey ? Color(hex: "#FF6B35") : Color(hex: "#855C23"))
                            }
                            .position(x: CGFloat(positions[index].x), y: CGFloat(positions[index].y))
                        }
                    }
                    .frame(width: 400, height: 400)
                    .padding(.horizontal)
                    .padding(.bottom, 100)

                    // 开始生成按钮 - 使用NavigationLink
                    NavigationLink {
                        nextView
                    } label: {
                        ZStack {
                            Image("button1")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 250, height: 44)

                            Text("开始生成")
                                .font(.custom("WSQuanXing", size: 24))
                                .fontWeight(.bold)
                                .foregroundColor(
                                    viewModel.selectedStyle.isEmpty ?
                                        Color(hex: "#CCCCCC") :
                                        Color(hex: "#855C23")
                                )
                        }
                    }
                    .disabled(viewModel.selectedStyle.isEmpty)
                    .opacity(viewModel.selectedStyle.isEmpty ? 0.6 : 1.0)
                    
                    // // 显示已选择的视频数量
                    // Text("已选择 \(viewModel.selectedVideos.count) 个视频")
                    //     .font(.custom("STKaiti", size: 14))
                    //     .foregroundColor(Color(hex: "#2F2617"))
                    
                    // // 调试信息
                    // Text("状态: \(viewModel.uploadStatus.rawValue)")
                    //     .font(.caption)
                    //     .foregroundColor(.gray)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            // .navigationBarBackButtonHidden(false)
            // .toolbarBackground(Color.clear, for: .navigationBar)
        .onAppear {
            print("SelectStyleView: 已选择 \(viewModel.selectedVideos.count) 个视频")
            print("SelectStyleView: 初始状态 \(viewModel.uploadStatus.rawValue)")
        }
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
    @State private var navigateToResults = false
    @State private var hasNavigated = false  // 防止重复导航

    var body: some View {
        ProcessingView(viewModel: viewModel)
            .onAppear {
                // 开始真实的上传和处理流程
                if viewModel.uploadStatus == .pending {
                    _ = viewModel.startGeneration()
                }
                // 重置导航状态
                hasNavigated = false
                navigateToResults = false
            }
            .onChange(of: viewModel.uploadStatus) { _, newStatus in
                print("🔄 RealProcessingView: 状态变化 -> \(newStatus)")
                print("🔄 RealProcessingView: comicResult 是否存在: \(viewModel.comicResult != nil)")
                print("🔄 RealProcessingView: hasNavigated: \(hasNavigated)")

                if newStatus == .completed && !hasNavigated {
                    print("✅ RealProcessingView: 准备导航到结果页面")
                    hasNavigated = true  // 标记已处理，防止重复
                    // 延迟一秒后导航到结果页面
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        print("🚀 RealProcessingView: 开始导航")
                        navigateToResults = true
                    }
                } else if newStatus == .completed && hasNavigated {
                    print("⚠️ RealProcessingView: 已经导航过了，跳过")
                } else if newStatus == .failed {
                    print("❌ RealProcessingView: 处理失败，不导航")
                }
            }
            .navigationDestination(isPresented: $navigateToResults) {
                if let comicResult = viewModel.comicResult {
                    OpenResultsView(comicResult: comicResult)
                } else {
                    // 错误处理视图
                    Text("生成失败，请重试")
                        .foregroundColor(.red)
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
