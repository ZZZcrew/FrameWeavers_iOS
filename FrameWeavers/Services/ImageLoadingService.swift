import SwiftUI
import Combine

/// 图片加载服务 - 负责处理图片的异步加载逻辑
/// 遵循MVVM架构，将网络逻辑从View中分离
class ImageLoadingService: ObservableObject {
    static let shared = ImageLoadingService()
    
    // MARK: - Properties
    private var imageCache: [String: UIImage] = [:]
    private var loadingTasks: [String: Task<UIImage?, Never>] = [:]
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 加载图片
    /// - Parameter imageUrl: 图片URL或本地图片名称
    /// - Returns: 异步返回UIImage或nil
    func loadImage(from imageUrl: String) async -> UIImage? {
        // 检查缓存
        if let cachedImage = imageCache[imageUrl] {
            return cachedImage
        }
        
        // 检查是否已有正在进行的加载任务
        if let existingTask = loadingTasks[imageUrl] {
            return await existingTask.value
        }
        
        // 创建新的加载任务
        let task = Task<UIImage?, Never> {
            await performImageLoading(from: imageUrl)
        }
        
        loadingTasks[imageUrl] = task
        let result = await task.value
        loadingTasks.removeValue(forKey: imageUrl)
        
        return result
    }
    
    /// 预加载图片
    /// - Parameter imageUrls: 图片URL数组
    func preloadImages(_ imageUrls: [String]) {
        for imageUrl in imageUrls {
            Task {
                _ = await loadImage(from: imageUrl)
            }
        }
    }
    
    /// 清除缓存
    func clearCache() {
        imageCache.removeAll()
        // 取消所有正在进行的任务
        for task in loadingTasks.values {
            task.cancel()
        }
        loadingTasks.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func performImageLoading(from imageUrl: String) async -> UIImage? {
        // 首先检查是否是本地图片
        if let localImage = UIImage(named: imageUrl) {
            imageCache[imageUrl] = localImage
            return localImage
        }
        
        // 如果不是本地图片，尝试从网络加载
        guard let url = URL(string: imageUrl) else {
            print("❌ ImageLoadingService: 无效的图片URL: \(imageUrl)")
            return nil
        }
        
        print("🖼️ ImageLoadingService: 开始加载图片: \(imageUrl)")
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            guard let image = UIImage(data: data) else {
                print("❌ ImageLoadingService: 无法解析图片数据")
                return nil
            }
            
            print("✅ ImageLoadingService: 图片加载成功")
            imageCache[imageUrl] = image
            return image
            
        } catch {
            print("❌ ImageLoadingService: 图片加载失败: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - 图片加载状态
enum ImageLoadingState {
    case idle
    case loading
    case loaded(UIImage)
    case failed
}

/// 图片加载ViewModel - 用于单个图片的加载状态管理
@Observable
class ImageLoadingViewModel {
    var state: ImageLoadingState = .idle
    
    private let imageUrl: String
    private let imageService: ImageLoadingService
    
    init(imageUrl: String, imageService: ImageLoadingService = .shared) {
        self.imageUrl = imageUrl
        self.imageService = imageService
    }
    
    /// 开始加载图片
    func loadImage() {
        guard case .idle = state else { return }
        
        state = .loading
        
        Task { @MainActor in
            if let image = await imageService.loadImage(from: imageUrl) {
                state = .loaded(image)
            } else {
                state = .failed
            }
        }
    }
    
    /// 重新加载图片
    func reloadImage() {
        state = .idle
        loadImage()
    }
}
