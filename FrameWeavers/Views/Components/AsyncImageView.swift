import SwiftUI
import UIKit

/// 异步图片加载组件 - 支持本地和网络图片，符合MVVM架构
struct AsyncImageView: View {
    let imageUrl: String
    @State private var image: UIImage?
    @State private var isLoading = true

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
            } else if isLoading {
                // 加载中显示占位符
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
            } else {
                // 加载失败显示本地图片或占位符
                if UIImage(named: imageUrl) != nil {
                    Image(imageUrl)
                        .resizable()
                } else {
                    VStack {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("图片加载失败")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.1))
                }
            }
        }
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        // 首先检查是否是本地图片
        if let localImage = UIImage(named: imageUrl) {
            self.image = localImage
            self.isLoading = false
            return
        }

        // 如果不是本地图片，尝试从网络加载
        guard let url = URL(string: imageUrl) else {
            print("❌ AsyncImageView: 无效的图片URL: \(imageUrl)")
            isLoading = false
            return
        }

        print("🖼️ AsyncImageView: 开始加载图片: \(imageUrl)")

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false

                if let error = error {
                    print("❌ AsyncImageView: 图片加载失败: \(error.localizedDescription)")
                    return
                }

                guard let data = data, let loadedImage = UIImage(data: data) else {
                    print("❌ AsyncImageView: 无法解析图片数据")
                    return
                }

                print("✅ AsyncImageView: 图片加载成功")
                self.image = loadedImage
            }
        }.resume()
    }
}

// MARK: - Preview
struct AsyncImageView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // 本地图片预览
            AsyncImageView(imageUrl: "Image1")
                .frame(width: 200, height: 150)
                .cornerRadius(8)
            
            // 网络图片预览（示例）
            AsyncImageView(imageUrl: "https://example.com/image.jpg")
                .frame(width: 200, height: 150)
                .cornerRadius(8)
        }
        .padding()
    }
}
