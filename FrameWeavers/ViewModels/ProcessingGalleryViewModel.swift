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
    @Published var filmstripDisplayImages: [DisplayImageData] = [] // 响应式胶片显示数据

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
        setupReactiveDataFlow()
    }

    /// 设置响应式数据流 - 符合Combine最佳实践
    private func setupReactiveDataFlow() {
        // 响应baseFrames变化，自动更新filmstripDisplayImages
        $baseFrames
            .map { [weak self] frames -> [DisplayImageData] in
                guard let self = self else { return [] }

                if !frames.isEmpty {
                    // 真实模式：使用后端基础帧数据，不显示本地死数据
                    print("🎬 使用真实模式：后端基础帧数据，数量: \(frames.count)")
                    return frames.map { frame in
                        DisplayImageData(
                            id: frame.id.uuidString,
                            imageSource: .remote(url: frame.thumbnailURL),
                            fallbackName: nil  // 真实模式下不使用fallback
                        )
                    }
                } else {
                    // 示例模式：只在没有后端数据时使用本地图片
                    print("🎭 使用示例模式：本地图片数据")
                    return self.imageNames.map { name in
                        DisplayImageData(
                            id: name,
                            imageSource: .local(name: name),
                            fallbackName: name
                        )
                    }
                }
            }
            .assign(to: &$filmstripDisplayImages)
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


