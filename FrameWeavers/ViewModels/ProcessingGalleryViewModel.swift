import SwiftUI
import Combine
import Foundation

/// 处理画廊的视图模型
class ProcessingGalleryViewModel: ObservableObject {
    @Published var mainImageName: String = "Image1"
    @Published var flyingImageInfo: FlyingImageInfo?
    @Published var hideSourceImageId: String?
    @Published var stackedImages: [String] = [] // 已堆叠的图片列表
    @Published var baseFrames: [BaseFrameData] = [] // 基础帧数据
    @Published var isUsingBaseFrames: Bool = false // 是否使用基础帧
    @Published var filmstripDisplayImages: [DisplayImageData] = [] // 保留兼容性，但不再使用
    @Published var isExampleMode: Bool = false // 是否为示例模式

    let imageNames = ["Image1", "Image2", "Image3", "Image4"]
    private var cancellables = Set<AnyCancellable>() // Combine订阅管理

    /// 基础帧数据映射，用于组件访问
    var baseFrameDataMap: [String: BaseFrameData] {
        var map: [String: BaseFrameData] = [:]
        for frame in baseFrames {
            map[frame.id.uuidString] = frame
        }
        return map
    }

    /// 胶片传送带配置
    var filmstripConfig: FilmstripConfiguration {
        return .default
    }

    init() {
        mainImageName = imageNames.first ?? ""
        // 不再需要复杂的响应式数据流，FilmstripView 直接使用 baseFrames
    }

    // 移除了复杂的响应式数据流，FilmstripView 现在直接使用 baseFrames 数据

    /// 设置基础帧数据
    func setBaseFrames(_ frames: [BaseFrameData]) {
        print("🎨 ProcessingGalleryViewModel: 设置基础帧数据, 数量: \(frames.count)")
        baseFrames = frames
        isUsingBaseFrames = !frames.isEmpty
        isExampleMode = false  // 有真实数据时，退出示例模式
        if let firstFrame = frames.first {
            mainImageName = firstFrame.id.uuidString
            print("🖼️ 设置主图片为: \(mainImageName)")
            print("🔗 第一个基础帧URL: \(firstFrame.thumbnailURL?.absoluteString ?? "nil")")
        }
        print("✅ isUsingBaseFrames: \(isUsingBaseFrames)")
    }

    /// 设置为示例模式
    func setExampleMode(_ isExample: Bool) {
        print("🎭 ProcessingGalleryViewModel: 设置示例模式: \(isExample)")
        isExampleMode = isExample
        if isExample {
            // 示例模式下重置为第一个本地图片
            mainImageName = imageNames.first ?? ""
            isUsingBaseFrames = false
        }
    }

    /// 获取基础帧数据
    func getBaseFrame(for id: String) -> BaseFrameData? {
        return baseFrames.first { $0.id.uuidString == id }
    }

    // 移除了 createLoadingPlaceholders 方法，现在由 FilmstripView 内部处理


    
    /// 触发一次图片跳跃动画
    func triggerJumpAnimation(from frames: [String: CGRect]) {
        guard let centerImageId = findCenterImageId(from: frames),
              frames["photoStackTarget"] != nil else { return }

        // 如果图片已经在堆叠中，跳过
        if centerImageId == mainImageName || stackedImages.contains(centerImageId) { return }

        guard let sourceFrame = frames[centerImageId] else { return }

        self.flyingImageInfo = FlyingImageInfo(id: centerImageId, sourceFrame: sourceFrame)
        self.hideSourceImageId = centerImageId

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            // 将当前主图片添加到堆叠中（如果不为空且不在堆叠中）
            if !self.mainImageName.isEmpty && !self.stackedImages.contains(self.mainImageName) {
                self.stackedImages.append(self.mainImageName)
            }

            // 设置新的主图片
            self.mainImageName = centerImageId
            self.flyingImageInfo = nil
            self.hideSourceImageId = nil
        }
    }
    
    /// 根据Frame信息计算当前在中心的图片ID
    private func findCenterImageId(from frames: [String: CGRect]) -> String? {
        let screenCenter = UIScreen.main.bounds.midX
        var closestImageId: String?
        var minDistance = CGFloat.infinity

        // 过滤出有效的图片frame，并找到最接近屏幕中心的
        for (id, frame) in frames {
            // 确保frame不为零且图片名在列表中
            let isValidId = isUsingBaseFrames ?
                baseFrames.contains { $0.id.uuidString == id } :
                imageNames.contains(id)
            guard isValidId, frame != .zero else { continue }

            let distance = abs(frame.midX - screenCenter)
            if distance < minDistance {
                minDistance = distance
                closestImageId = id
            }
        }
        return closestImageId
    }
}


