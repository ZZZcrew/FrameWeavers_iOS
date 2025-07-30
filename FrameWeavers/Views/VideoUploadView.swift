import SwiftUI
import PhotosUI

/// 视频上传主视图 - 遵循MVVM架构，只负责UI展示
struct VideoUploadView: View {
    @StateObject private var viewModel = VideoUploadViewModel()

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

                    // 导航到选择风格界面
                    NavigationLink(
                        destination: SelectStyleView(viewModel: viewModel),
                        isActive: $viewModel.shouldNavigateToStyleSelection
                    ) {
                        EmptyView()
                    }
                }
                .padding()
            }
        }
    }
}
