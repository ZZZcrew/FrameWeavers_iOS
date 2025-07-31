import SwiftUI
import Combine
import Foundation

/// 处理画廊的视图模型
class ProcessingGalleryViewModel: ObservableObject {
    @Published var mainImageName: String = "Image1"
    @Published var flyingImageInfo: FlyingImageInfo?
    @Published var hideSourceImageId: String?
    @Published var currentScrollIndex: Int = 0 {
        didSet {
            updateScrollOffset()
        }
    }
    @Published var stackedImages: [String] = [] // 已堆叠的图片列表
    @Published var baseFrames: [BaseFrameData] = [] // 基础帧数据
    @Published var isUsingBaseFrames: Bool = false // 是否使用基础帧
    @Published var scrollOffset: CGFloat = 0 // 滚动偏移量

    let imageNames = ["Image1", "Image2", "Image3", "Image4", "Image1", "Image2", "Image3", "Image4"]

    // 胶片帧的尺寸常量
    private let frameWidth: CGFloat = 120
    private let frameSpacing: CGFloat = 10

    var loopedImageNames: [String] {
        if isUsingBaseFrames && !baseFrames.isEmpty {
            let frameIds = baseFrames.map { $0.id.uuidString }
            return frameIds + frameIds + frameIds
        } else {
            return imageNames + imageNames + imageNames
        }
    }

    var currentImageNames: [String] {
        if isUsingBaseFrames && !baseFrames.isEmpty {
            return baseFrames.map { $0.id.uuidString }
        } else {
            return imageNames
        }
    }

    /// 基础帧数据映射，用于组件访问
    var baseFrameDataMap: [String: BaseFrameData] {
        var map: [String: BaseFrameData] = [:]
        for frame in baseFrames {
            map[frame.id.uuidString] = frame
        }
        return map
    }

    init() {
        mainImageName = imageNames.first ?? ""
    }

    /// 设置基础帧数据
    func setBaseFrames(_ frames: [BaseFrameData]) {
        print("🎨 ProcessingGalleryViewModel: 设置基础帧数据, 数量: \(frames.count)")
        baseFrames = frames
        isUsingBaseFrames = !frames.isEmpty
        if let firstFrame = frames.first {
            mainImageName = firstFrame.id.uuidString
            print("🖼️ 设置主图片为: \(mainImageName)")
            print("🔗 第一个基础帧URL: \(firstFrame.thumbnailURL?.absoluteString ?? "nil")")
        }
        print("✅ isUsingBaseFrames: \(isUsingBaseFrames)")
    }

    /// 获取基础帧数据
    func getBaseFrame(for id: String) -> BaseFrameData? {
        return baseFrames.first { $0.id.uuidString == id }
    }

    /// 更新滚动偏移量
    private func updateScrollOffset() {
        let itemWidth = frameWidth + frameSpacing
        let totalItems = currentImageNames.count

        // 确保索引在有效范围内
        guard totalItems > 0 else { return }

        // 计算当前索引在原始数组中的位置（处理循环）
        let normalizedIndex = currentScrollIndex % totalItems

        // 计算偏移量，使用平滑的动画
        let targetOffset = CGFloat(normalizedIndex) * itemWidth

        withAnimation(.easeInOut(duration: 0.8)) {
            scrollOffset = targetOffset
        }

        // 当滚动到一定程度时重置，实现无缝循环
        if currentScrollIndex >= totalItems * 2 {
            // 延迟重置，避免动画冲突
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                self.currentScrollIndex = self.currentScrollIndex % totalItems
                // 立即设置偏移量，不使用动画
                self.scrollOffset = CGFloat(self.currentScrollIndex) * itemWidth
            }
        }
    }
    
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

// MARK: - VideoUploadViewModel Extension

extension VideoUploadViewModel {
    /// 使用项目中现有的图片资源
    var mockImageNames: [String] {
        return ["Image1", "Image2", "Image3", "Image4", "Image1", "Image2", "Image3", "Image4"]
    }
    
    /// 为了无缝滚动，复制数组
    var loopedImageNames: [String] {
        let images = mockImageNames
        return images + images + images
    }
}
