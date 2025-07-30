import SwiftUI
import PhotosUI

/// 视频上传主视图 - 遵循MVVM架构，只负责UI展示
struct VideoUploadView: View {
    @State private var viewModel = VideoUploadViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景图片
                Image("背景")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    WelcomeView()
                        .environment(viewModel)

                    // 导航到选择风格界面
                    NavigationLink(
                        destination: SelectStyleView().environment(viewModel),
                        isActive: .constant(viewModel.shouldNavigateToStyleSelection)
                    ) {
                        EmptyView()
                    }
                }
                .padding()
            }
        }
        .environment(viewModel)
    }
}
