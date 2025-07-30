import SwiftUI

/// 异步图片加载组件 - 纯UI组件，遵循MVVM架构
/// 使用ImageLoadingService处理图片加载逻辑
struct AsyncImageView: View {
    let imageUrl: String
    @State private var viewModel: ImageLoadingViewModel
    
    init(imageUrl: String) {
        self.imageUrl = imageUrl
        self._viewModel = State(wrappedValue: ImageLoadingViewModel(imageUrl: imageUrl))
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle:
                Color.clear
                    .onAppear {
                        viewModel.loadImage()
                    }
                
            case .loading:
                LoadingPlaceholderView()
                
            case .loaded(let image):
                Image(uiImage: image)
                    .resizable()
                
            case .failed:
                ErrorPlaceholderView(
                    imageUrl: imageUrl,
                    onRetry: {
                        viewModel.reloadImage()
                    }
                )
            }
        }
    }
}

// MARK: - 加载中占位符组件
struct LoadingPlaceholderView: View {
    var body: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("加载中...")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.1))
    }
}

// MARK: - 错误占位符组件
struct ErrorPlaceholderView: View {
    let imageUrl: String
    let onRetry: () -> Void
    
    var body: some View {
        Group {
            // 尝试显示本地图片
            if UIImage(named: imageUrl) != nil {
                Image(imageUrl)
                    .resizable()
            } else {
                // 显示错误占位符
                VStack {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("图片加载失败")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Button("重试") {
                        onRetry()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.1))
            }
        }
    }
}

// MARK: - 预览
struct AsyncImageView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // 本地图片预览
            AsyncImageView(imageUrl: "Image1")
                .frame(width: 200, height: 150)
                .previewDisplayName("本地图片")
            
            // 网络图片预览（模拟）
            AsyncImageView(imageUrl: "https://example.com/image.jpg")
                .frame(width: 200, height: 150)
                .previewDisplayName("网络图片")
            
            // 错误状态预览
            AsyncImageView(imageUrl: "invalid_url")
                .frame(width: 200, height: 150)
                .previewDisplayName("错误状态")
        }
    }
}
