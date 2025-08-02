import Foundation
import UIKit

/// 本地图片存储服务
/// 负责下载、保存和管理画册图片的本地存储
class LocalImageStorageService {
    
    // MARK: - 单例
    static let shared = LocalImageStorageService()
    
    // MARK: - 私有属性
    private let fileManager = FileManager.default
    private let imageDirectory: URL
    
    // MARK: - 初始化
    private init() {
        // 创建图片存储目录
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        imageDirectory = documentsPath.appendingPathComponent("ComicImages")
        
        // 确保目录存在
        createImageDirectoryIfNeeded()
    }
    
    // MARK: - 公共方法
    
    /// 保存画册的所有图片到本地
    /// - Parameter comicResult: 画册结果
    /// - Returns: 更新后的画册结果（图片URL替换为本地路径）
    func saveComicImages(_ comicResult: ComicResult) async -> ComicResult {
        print("🖼️ 开始保存画册图片到本地: \(comicResult.title)")
        
        var updatedPanels: [ComicPanel] = []
        
        // 下载并保存每个页面的图片
        for panel in comicResult.panels {
            let localImagePath = await downloadAndSaveImage(
                from: panel.imageUrl,
                comicId: comicResult.comicId,
                panelNumber: panel.panelNumber
            )
            
            let updatedPanel = ComicPanel(
                panelNumber: panel.panelNumber,
                imageUrl: localImagePath ?? panel.imageUrl, // 如果下载失败，保留原URL
                narration: panel.narration
            )
            updatedPanels.append(updatedPanel)
        }
        
        // 创建更新后的画册结果
        let updatedComicResult = ComicResult(
            comicId: comicResult.comicId,
            deviceId: comicResult.deviceId,
            title: comicResult.title,
            summary: comicResult.summary,
            originalVideoTitle: comicResult.originalVideoTitle,
            creationDate: comicResult.creationDate,
            panelCount: comicResult.panelCount,
            panels: updatedPanels,
            finalQuestions: comicResult.finalQuestions
        )
        
        print("✅ 画册图片保存完成: \(comicResult.title)")
        return updatedComicResult
    }
    
    /// 检查本地图片是否存在
    /// - Parameter imagePath: 图片路径
    /// - Returns: 是否存在
    func localImageExists(at imagePath: String) -> Bool {
        // 如果是本地路径，检查文件是否存在
        if imagePath.hasPrefix("ComicImages/") {
            let fullPath = imageDirectory.appendingPathComponent(String(imagePath.dropFirst(12))) // 移除 "ComicImages/" 前缀
            return fileManager.fileExists(atPath: fullPath.path)
        }
        return false
    }
    
    /// 获取本地图片的完整路径
    /// - Parameter imagePath: 相对路径
    /// - Returns: 完整的本地URL
    func getLocalImageURL(for imagePath: String) -> URL? {
        if imagePath.hasPrefix("ComicImages/") {
            let relativePath = String(imagePath.dropFirst(12)) // 移除 "ComicImages/" 前缀
            return imageDirectory.appendingPathComponent(relativePath)
        }
        return nil
    }
    
    /// 删除画册的所有本地图片
    /// - Parameter comicId: 画册ID
    func deleteComicImages(for comicId: String) {
        let comicDirectory = imageDirectory.appendingPathComponent(comicId)
        
        do {
            if fileManager.fileExists(atPath: comicDirectory.path) {
                try fileManager.removeItem(at: comicDirectory)
                print("✅ 已删除画册图片: \(comicId)")
            }
        } catch {
            print("❌ 删除画册图片失败: \(error)")
        }
    }
    
    /// 清理所有本地图片缓存
    func clearAllImages() {
        do {
            if fileManager.fileExists(atPath: imageDirectory.path) {
                try fileManager.removeItem(at: imageDirectory)
                createImageDirectoryIfNeeded()
                print("✅ 已清理所有本地图片缓存")
            }

            // MVP: 同时清理网络图片缓存
            clearNetworkImageCache()
        } catch {
            print("❌ 清理图片缓存失败: \(error)")
        }
    }

    /// MVP: 清理网络图片缓存
    func clearNetworkImageCache() {
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }

        let cacheDirectory = documentsPath.appendingPathComponent("ImageCache")

        do {
            if fileManager.fileExists(atPath: cacheDirectory.path) {
                try fileManager.removeItem(at: cacheDirectory)
                print("✅ 已清理网络图片缓存")
            }
        } catch {
            print("❌ 清理网络图片缓存失败: \(error)")
        }
    }
    
    /// 获取本地图片缓存大小
    /// - Returns: 缓存大小（字节）
    func getCacheSize() -> Int64 {
        var totalSize: Int64 = 0

        // 计算画册图片缓存大小
        if let enumerator = fileManager.enumerator(at: imageDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                    totalSize += Int64(resourceValues.fileSize ?? 0)
                } catch {
                    continue
                }
            }
        }

        // MVP: 计算网络图片缓存大小
        if let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let cacheDirectory = documentsPath.appendingPathComponent("ImageCache")
            if let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
                for case let fileURL as URL in enumerator {
                    do {
                        let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                        totalSize += Int64(resourceValues.fileSize ?? 0)
                    } catch {
                        continue
                    }
                }
            }
        }

        return totalSize
    }
    
    // MARK: - 私有方法
    
    /// 创建图片存储目录
    private func createImageDirectoryIfNeeded() {
        do {
            try fileManager.createDirectory(at: imageDirectory, withIntermediateDirectories: true)
        } catch {
            print("❌ 创建图片存储目录失败: \(error)")
        }
    }
    
    /// 下载并保存单张图片
    /// - Parameters:
    ///   - imageUrl: 图片URL
    ///   - comicId: 画册ID
    ///   - panelNumber: 页面编号
    /// - Returns: 本地图片路径
    private func downloadAndSaveImage(from imageUrl: String, comicId: String, panelNumber: Int) async -> String? {
        // 如果已经是本地路径，直接返回
        if imageUrl.hasPrefix("ComicImages/") {
            return imageUrl
        }
        
        guard let url = URL(string: imageUrl) else {
            print("❌ 无效的图片URL: \(imageUrl)")
            return nil
        }
        
        do {
            // 下载图片数据
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // 创建画册专用目录
            let comicDirectory = imageDirectory.appendingPathComponent(comicId)
            try fileManager.createDirectory(at: comicDirectory, withIntermediateDirectories: true)
            
            // 生成本地文件名
            let fileName = "panel_\(panelNumber).jpg"
            let localURL = comicDirectory.appendingPathComponent(fileName)
            
            // 保存图片数据
            try data.write(to: localURL)
            
            // 返回相对路径
            let relativePath = "ComicImages/\(comicId)/\(fileName)"
            print("✅ 图片保存成功: \(relativePath)")
            return relativePath
            
        } catch {
            print("❌ 下载保存图片失败: \(error)")
            return nil
        }
    }
}

// MARK: - 扩展：格式化缓存大小

extension LocalImageStorageService {
    /// 获取格式化的缓存大小字符串
    /// - Returns: 格式化的大小字符串（如 "2.5 MB"）
    func getFormattedCacheSize() -> String {
        let sizeInBytes = getCacheSize()
        return ByteCountFormatter.string(fromByteCount: sizeInBytes, countStyle: .file)
    }
}
