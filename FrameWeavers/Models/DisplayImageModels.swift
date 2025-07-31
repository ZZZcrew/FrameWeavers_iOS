import Foundation
import SwiftUI

// MARK: - 显示图片相关数据模型

/// 显示图片数据 - 统一本地图片和远程图片的数据模型
struct DisplayImageData: Identifiable, Hashable {
    let id: String
    let imageSource: ImageSource
    let fallbackName: String?
    
    init(id: String, imageSource: ImageSource, fallbackName: String? = nil) {
        self.id = id
        self.imageSource = imageSource
        self.fallbackName = fallbackName
    }
}

/// 图片来源类型 - 区分本地图片和远程图片
enum ImageSource: Hashable {
    case local(name: String)
    case remote(url: URL?)
    
    /// 是否为本地图片
    var isLocal: Bool {
        switch self {
        case .local:
            return true
        case .remote:
            return false
        }
    }
    
    /// 是否为远程图片
    var isRemote: Bool {
        return !isLocal
    }
    
    /// 获取本地图片名称
    var localImageName: String? {
        switch self {
        case .local(let name):
            return name
        case .remote:
            return nil
        }
    }
    
    /// 获取远程图片URL
    var remoteURL: URL? {
        switch self {
        case .local:
            return nil
        case .remote(let url):
            return url
        }
    }
}

// MARK: - 胶片传送带配置

/// 胶片传送带配置参数
struct FilmstripConfiguration {
    let frameWidth: CGFloat
    let frameHeight: CGFloat
    let frameSpacing: CGFloat
    let scrollSpeed: Double // 每秒移动像素数
    let repeatCount: Int // 重复图片数量以实现无限滚动
    
    static let `default` = FilmstripConfiguration(
        frameWidth: 120,
        frameHeight: 80,
        frameSpacing: 10,
        scrollSpeed: 30,
        repeatCount: 50
    )
}
