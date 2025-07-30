import SwiftUI
import PhotosUI

struct VideoUploadView: View {
    @StateObject private var viewModel = VideoUploadViewModel()
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var navigateToStyleSelection = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景图片
                Image("背景")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    WelcomeView(selectedItems: $selectedItems)
                        .onChange(of: selectedItems) { _, newItems in
                            Task {
                                let videoURLs = await viewModel.processSelectedItems(newItems)

                                await MainActor.run {
                                    viewModel.selectVideos(videoURLs)
                                    // 选择视频后自动跳转到选择风格界面
                                    if !videoURLs.isEmpty {
                                        navigateToStyleSelection = true
                                    }
                                }
                            }
                        }
                    
                    // 导航到选择风格界面，传递共享的ViewModel实例
                    NavigationLink(
                        destination: SelectStyleView(viewModel: viewModel),
                        isActive: $navigateToStyleSelection
                    ) {
                        EmptyView()
                    }
                }
                .padding()
            }
        }
    }
}
