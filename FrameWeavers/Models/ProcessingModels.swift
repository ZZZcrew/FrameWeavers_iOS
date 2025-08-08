import SwiftUI
import Foundation

// MARK: - Data Models and PreferenceKeys

/// 用于在视图树中向上传递视图的Frame信息
struct FramePreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]

    static func reduce(value: inout [String : CGRect], nextValue: () -> [String : CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

/// 飞跃动画图片信息 - MVP版本
struct FlyingImageInfo: Identifiable {
    let id: String
    let imageSource: ImageSource  // 使用统一的图片源类型
    let baseFrame: BaseFrameData? // 可选的基础帧数据
}

