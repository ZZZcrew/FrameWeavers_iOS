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
                        .font(.custom("STKaiti", size: 12))
                        .foregroundColor(Color(hex: "#2F2617"))
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
                            .foregroundColor(Color(hex: "#2F2617").opacity(0.5))
                        Text("图片加载失败")
                            .font(.custom("STKaiti", size: 12))
                            .foregroundColor(Color(hex: "#2F2617"))
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
        // 首先检查是否是本地缓存的图片
        if imageUrl.hasPrefix("ComicImages/") {
            loadLocalCachedImage()
            return
        }

        // 然后检查是否是资源包中的本地图片
        if let localImage = UIImage(named: imageUrl) {
            self.image = localImage
            self.isLoading = false
            return
        }

        // MVP: 检查是否有缓存的网络图片
        if let cachedImage = loadCachedNetworkImage() {
            self.image = cachedImage
            self.isLoading = false
            print("✅ AsyncImageView: 使用缓存图片")
            return
        }

        // 如果不是本地图片，尝试从网络加载
        guard let url = URL(string: imageUrl) else {
            print("❌ AsyncImageView: 无效的图片URL: \(imageUrl)")
            isLoading = false
            return
        }

        print("🖼️ AsyncImageView: 开始加载网络图片: \(imageUrl)")

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

                print("✅ AsyncImageView: 网络图片加载成功")
                self.image = loadedImage

                // MVP: 自动缓存网络图片到本地
                if self.imageUrl.contains("frame-api.zeabur.app") {
                    Task {
                        await self.cacheImageToLocal(data: data)
                    }
                }
            }
        }.resume()
    }

    /// 加载本地缓存的图片
    private func loadLocalCachedImage() {
        guard let localURL = LocalImageStorageService.shared.getLocalImageURL(for: imageUrl) else {
            print("❌ AsyncImageView: 无法获取本地图片路径: \(imageUrl)")
            isLoading = false
            return
        }

        do {
            let imageData = try Data(contentsOf: localURL)
            if let localImage = UIImage(data: imageData) {
                self.image = localImage
                self.isLoading = false
                print("✅ AsyncImageView: 本地缓存图片加载成功: \(imageUrl)")
            } else {
                print("❌ AsyncImageView: 无法解析本地图片数据: \(imageUrl)")
                isLoading = false
            }
        } catch {
            print("❌ AsyncImageView: 读取本地图片失败: \(error)")
            isLoading = false
        }
    }

    /// MVP: 加载缓存的网络图片
    /// - Returns: 缓存的图片，如果不存在则返回nil
    private func loadCachedNetworkImage() -> UIImage? {
        // 生成缓存文件名（基于URL的哈希值）
        let fileName = "cached_\(imageUrl.hashValue.magnitude).jpg"

        // 获取缓存目录
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        let cacheDirectory = documentsPath.appendingPathComponent("ImageCache")
        let fileURL = cacheDirectory.appendingPathComponent(fileName)

        // 检查文件是否存在
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        // 加载图片
        do {
            let imageData = try Data(contentsOf: fileURL)
            return UIImage(data: imageData)
        } catch {
            print("❌ AsyncImageView: 读取缓存图片失败: \(error)")
            return nil
        }
    }

    /// MVP: 简单缓存网络图片到本地
    /// - Parameter data: 图片数据
    private func cacheImageToLocal(data: Data) async {
        // 生成缓存文件名（基于URL的哈希值）
        let fileName = "cached_\(imageUrl.hashValue.magnitude).jpg"

        // 获取缓存目录
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }

        let cacheDirectory = documentsPath.appendingPathComponent("ImageCache")
        let fileURL = cacheDirectory.appendingPathComponent(fileName)

        do {
            // 创建缓存目录
            try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

            // 保存图片数据
            try data.write(to: fileURL)
            print("✅ AsyncImageView: 图片已缓存到本地: \(fileName)")
        } catch {
            print("❌ AsyncImageView: 缓存图片失败: \(error)")
        }
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
