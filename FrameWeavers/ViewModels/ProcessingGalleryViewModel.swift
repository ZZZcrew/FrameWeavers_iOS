import SwiftUI
import Combine
import Foundation

/// 处理画廊的视图模型
class ProcessingGalleryViewModel: ObservableObject {
    @Published var mainImageName: String = "" // 初始为空，避免死数据
    @Published var stackedImages: [String] = [] // 已堆叠的图片列表
    @Published var baseFrames: [BaseFrameData] = [] // 基础帧数据
    @Published var isUsingBaseFrames: Bool = false // 是否使用基础帧
    @Published var isExampleMode: Bool = false // 是否为示例模式
    @Published var hasValidData: Bool = false // 是否有有效数据

    // MARK: - 飞跃动画状态
    @Published var flyingImageInfo: FlyingImageInfo? // 当前飞跃的图片信息
    @Published var isAnimating: Bool = false // 是否正在执行动画

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
        // 初始化时不设置任何死数据，等待真实数据或示例数据
        print("🎬 ProcessingGalleryViewModel: 初始化，等待真实数据...")
    }

    // 移除了复杂的响应式数据流，FilmstripView 现在直接使用 baseFrames 数据

    /// 设置基础帧数据
    func setBaseFrames(_ frames: [BaseFrameData]) {
        print("🎨 ProcessingGalleryViewModel: 设置基础帧数据, 数量: \(frames.count)")
        baseFrames = frames
        isUsingBaseFrames = !frames.isEmpty
        isExampleMode = false  // 有真实数据时，退出示例模式
        hasValidData = !frames.isEmpty

        if let firstFrame = frames.first {
            mainImageName = firstFrame.id.uuidString
            print("🖼️ 设置主图片为: \(mainImageName)")
            print("🔗 第一个基础帧URL: \(firstFrame.thumbnailURL?.absoluteString ?? "nil")")
        } else {
            mainImageName = "" // 没有数据时保持为空
        }
        print("✅ isUsingBaseFrames: \(isUsingBaseFrames), hasValidData: \(hasValidData)")
    }

    /// 设置为示例模式
    func setExampleMode(_ isExample: Bool, comicResult: ComicResult? = nil) {
        print("🎭 ProcessingGalleryViewModel: 设置示例模式: \(isExample)")
        isExampleMode = isExample
        if isExample {
            // 示例模式下只使用画册数据，不使用死数据
            if let comicResult = comicResult, let firstPanel = comicResult.panels.first {
                mainImageName = firstPanel.imageUrl
                hasValidData = true
                print("🖼️ 示例模式使用画册图片: \(mainImageName)")
            } else {
                // 没有画册数据时保持为空，不显示死数据
                mainImageName = ""
                hasValidData = false
                print("⚠️ 示例模式但无画册数据，保持空白")
            }
            isUsingBaseFrames = false
        } else {
            hasValidData = !baseFrames.isEmpty
        }
    }

    /// 获取基础帧数据
    func getBaseFrame(for id: String) -> BaseFrameData? {
        return baseFrames.first { $0.id.uuidString == id }
    }

    // 移除了 createLoadingPlaceholders 方法，现在由 FilmstripView 内部处理

    /// 选择图片并传递到PhotoStackView（带飞跃动画）
    /// - Parameter imageId: 选中的图片ID
    func selectImage(_ imageId: String) {
        print("🖱️ ProcessingGalleryViewModel: 用户选择图片: \(imageId)")

        // 如果正在动画中或图片已经是主图片或已在堆叠中，跳过
        if isAnimating || imageId == mainImageName || stackedImages.contains(imageId) {
            print("⚠️ 图片已存在或正在动画中，跳过选择")
            return
        }

        // 验证图片ID是否有效
        let isValidId: Bool
        if isUsingBaseFrames {
            // 真实模式：检查基础帧数据
            isValidId = baseFrames.contains { $0.id.uuidString == imageId }
        } else if isExampleMode {
            // 示例模式：接受任何非空ID（因为可能来自画册数据）
            isValidId = !imageId.isEmpty
        } else {
            // 没有有效数据时，不接受任何选择
            isValidId = false
            print("⚠️ 没有有效数据，拒绝图片选择")
        }

        guard isValidId else {
            print("❌ 无效的图片ID: \(imageId), 模式: isUsingBaseFrames=\(isUsingBaseFrames), isExampleMode=\(isExampleMode)")
            return
        }

        // 开始飞跃动画
        startFlyingAnimation(for: imageId)
    }

    /// 直接设置当前图片ID（用于新的状态管理模式）
    /// - Parameter imageId: 新的图片ID
    func setCurrentImage(_ imageId: String) {
        print("🖼️ ProcessingGalleryViewModel: 直接设置当前图片: \(imageId)")
        
        // 验证图片ID是否有效
        let isValidId: Bool
        if isUsingBaseFrames {
            isValidId = baseFrames.contains { $0.id.uuidString == imageId }
        } else if isExampleMode {
            isValidId = !imageId.isEmpty
        } else {
            isValidId = false
        }

        guard isValidId else {
            print("❌ 无效的图片ID: \(imageId)")
            return
        }

        // 将当前主图片添加到堆叠中（如果不为空且不在堆叠中）
        if !mainImageName.isEmpty && !stackedImages.contains(mainImageName) {
            stackedImages.append(mainImageName)
            print("📚 将当前主图片添加到堆叠: \(mainImageName)")
        }

        // 设置新的主图片
        mainImageName = imageId
        print("🖼️ 设置新的主图片: \(mainImageName)")
    }

    /// 开始飞跃动画
    /// - Parameter imageId: 要飞跃的图片ID
    private func startFlyingAnimation(for imageId: String) {
        print("🚀 开始飞跃动画: \(imageId)")

        // 创建飞跃图片信息
        let imageSource: ImageSource
        let baseFrame: BaseFrameData?

        if isUsingBaseFrames {
            // 真实模式：使用基础帧数据
            baseFrame = baseFrames.first { $0.id.uuidString == imageId }
            imageSource = .remote(url: baseFrame?.thumbnailURL)
        } else {
            // 示例模式或默认模式：使用本地图片
            baseFrame = nil
            imageSource = .local(name: imageId)
        }

        flyingImageInfo = FlyingImageInfo(
            id: imageId,
            imageSource: imageSource,
            baseFrame: baseFrame
        )
        isAnimating = true

        // 动画完成后的处理（使用HTML中的0.4秒时长）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.completeFlyingAnimation(for: imageId)
        }
    }

    /// 完成飞跃动画
    /// - Parameter imageId: 飞跃完成的图片ID
    private func completeFlyingAnimation(for imageId: String) {
        print("✅ 完成飞跃动画: \(imageId)")

        // 将当前主图片添加到堆叠中（如果不为空且不在堆叠中）
        if !mainImageName.isEmpty && !stackedImages.contains(mainImageName) {
            stackedImages.append(mainImageName)
            print("📚 将当前主图片添加到堆叠: \(mainImageName)")
        }

        // 设置新的主图片
        mainImageName = imageId
        print("🖼️ 设置新的主图片: \(mainImageName)")

        // 清理动画状态
        flyingImageInfo = nil
        isAnimating = false
    }

}


