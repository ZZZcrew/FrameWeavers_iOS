import SwiftUI

/// 选择故事风格视图 - 遵循MVVM架构，只负责UI展示
struct SelectStyleView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: VideoUploadViewModel
    @StateObject private var galleryViewModel = ProcessingGalleryViewModel()
    
    // 定义故事风格
    private let storyStyles = [
        ("文艺哲学", "文 艺\n哲 学"),
        ("童话想象", "童 话\n想 象"),
        ("悬念反转", "悬 念\n反 转"),
        ("生活散文", "生 活\n散 文")
    ]
    
    var body: some View {
        NavigationStack {
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

                    // 开始生成按钮
                    Button(action: {
                        _ = viewModel.startGeneration()
                    }) {
                        ZStack {
                            Image("翻开画册")
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
            .navigationDestination(isPresented: $viewModel.shouldNavigateToProcessing) {
                ProcessingView(viewModel: viewModel)
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color(hex: "#2F2617"))
                    }
                }
            }
        }
        .onAppear {
            print("SelectStyleView: 已选择 \(viewModel.selectedVideos.count) 个视频")
            print("SelectStyleView: 初始状态 \(viewModel.uploadStatus.rawValue)")
        }
    }
}

// MARK: - SwiftUI Preview
struct SelectStyleView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = VideoUploadViewModel()
        viewModel.selectVideos([
            URL(string: "file:///mock/video1.mp4")!,
            URL(string: "file:///mock/video2.mp4")!
        ])
        return SelectStyleView(viewModel: viewModel)
    }
}
