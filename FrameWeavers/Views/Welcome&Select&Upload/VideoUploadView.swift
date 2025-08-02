import SwiftUI
import PhotosUI
import SwiftData

/// 视频上传主视图 - 遵循MVVM架构，只负责UI展示
struct VideoUploadView: View {
    @StateObject private var viewModel = VideoUploadViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景图片
                Image("背景")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    WelcomeView(viewModel: viewModel)
                }
                .padding()
            }
            .navigationDestination(isPresented: $viewModel.shouldNavigateToStyleSelection) {
                SelectStyleView(viewModel: viewModel)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            // 初始化历史记录服务
            viewModel.setHistoryService(modelContext: modelContext)
        }
    }
}
