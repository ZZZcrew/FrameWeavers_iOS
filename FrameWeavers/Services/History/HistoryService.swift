import Foundation
import SwiftData
import Combine

// MARK: - 历史记录管理服务

/// 历史画册管理服务
/// 负责历史画册的增删查改操作，包括同步和异步方法
class HistoryService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - 保存历史记录
    
    /// 保存新的画册到历史记录
    /// - Parameter comicResult: 要保存的画册结果
    /// - Returns: 是否保存成功
    func saveToHistory(_ comicResult: ComicResult, storyStyle: String?) -> Bool {
        do {
            // 检查是否已存在相同ID的记录
            let existingAlbum = try fetchHistoryAlbum(by: comicResult.comicId)
            if existingAlbum != nil {
                print("⚠️ 历史记录中已存在相同ID的画册: \(comicResult.comicId)")
                return false
            }
            
            // 创建新的历史记录
            let historyAlbum = HistoryAlbum(from: comicResult, storyStyle: storyStyle)
            modelContext.insert(historyAlbum)
            
            try modelContext.save()
            print("✅ 画册已保存到历史记录: \(comicResult.title)")
            return true
            
        } catch {
            print("❌ 保存历史记录失败: \(error)")
            return false
        }
    }

    /// 异步保存连环画结果到历史记录（带回调）
    /// - Parameters:
    ///   - comicResult: 要保存的连环画结果
    ///   - completion: 完成回调，返回是否保存成功
    func saveComicToHistory(
        _ comicResult: ComicResult,
        storyStyle: String?,
        completion: @escaping (Bool) -> Void = { _ in }
    ) {
        // 在后台队列执行保存操作
        Task {
            // 首先下载并保存图片到本地
            let comicWithLocalImages = await LocalImageStorageService.shared.saveComicImages(comicResult)

            // 然后保存到历史记录
            let success = self.saveToHistory(comicWithLocalImages, storyStyle: storyStyle)

            await MainActor.run {
                if success {
                    print("✅ 连环画已成功保存到历史记录（包含本地图片）: \(comicResult.title)")
                } else {
                    print("❌ 保存连环画到历史记录失败")
                }
                completion(success)
            }
        }
    }

    /// 异步保存连环画结果到历史记录（async/await）
    /// - Parameter comicResult: 要保存的连环画结果
    /// - Returns: 是否保存成功
    func saveComicToHistory(_ comicResult: ComicResult, storyStyle: String?) async -> Bool {
        // 首先下载并保存图片到本地
        let comicWithLocalImages = await LocalImageStorageService.shared.saveComicImages(comicResult)

        // 然后保存到历史记录
        let success = self.saveToHistory(comicWithLocalImages, storyStyle: storyStyle)

        if success {
            print("✅ 连环画已成功保存到历史记录（包含本地图片）: \(comicResult.title)")
        } else {
            print("❌ 保存连环画到历史记录失败")
        }

        return success
    }

    // MARK: - 查询历史记录
    
    /// 获取所有历史画册
    /// - Returns: 历史画册列表，按创建时间倒序排列
    func fetchAllHistoryAlbums() throws -> [HistoryAlbum] {
        let descriptor = FetchDescriptor<HistoryAlbum>(
            sortBy: [SortDescriptor(\.creationDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 根据ID获取特定的历史画册
    /// - Parameter id: 画册ID
    /// - Returns: 历史画册，如果不存在则返回nil
    func fetchHistoryAlbum(by id: String) throws -> HistoryAlbum? {
        let descriptor = FetchDescriptor<HistoryAlbum>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    /// 获取最近的历史画册
    /// - Parameter limit: 限制数量
    /// - Returns: 最近的历史画册列表
    func fetchRecentHistoryAlbums(limit: Int = 10) throws -> [HistoryAlbum] {
        var descriptor = FetchDescriptor<HistoryAlbum>(
            sortBy: [SortDescriptor(\.creationDate, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - 删除历史记录
    
    /// 删除指定的历史画册
    /// - Parameter historyAlbum: 要删除的历史画册
    /// - Returns: 是否删除成功
    func deleteHistoryAlbum(_ historyAlbum: HistoryAlbum) -> Bool {
        do {
            // 先删除本地图片
            LocalImageStorageService.shared.deleteComicImages(for: historyAlbum.id)

            // 再删除数据库记录
            modelContext.delete(historyAlbum)
            try modelContext.save()
            print("✅ 已删除历史画册（包含本地图片）: \(historyAlbum.title)")
            return true
        } catch {
            print("❌ 删除历史画册失败: \(error)")
            return false
        }
    }
    
    /// 根据ID删除历史画册
    /// - Parameter id: 画册ID
    /// - Returns: 是否删除成功
    func deleteHistoryAlbum(by id: String) -> Bool {
        do {
            if let album = try fetchHistoryAlbum(by: id) {
                return deleteHistoryAlbum(album)
            } else {
                print("⚠️ 未找到要删除的历史画册: \(id)")
                return false
            }
        } catch {
            print("❌ 查找要删除的历史画册失败: \(error)")
            return false
        }
    }
    
    /// 清空所有历史记录
    /// - Returns: 是否清空成功
    func clearAllHistory() -> Bool {
        do {
            let allAlbums = try fetchAllHistoryAlbums()

            // 先清空所有本地图片
            LocalImageStorageService.shared.clearAllImages()

            // 再删除数据库记录
            for album in allAlbums {
                modelContext.delete(album)
            }
            try modelContext.save()
            print("✅ 已清空所有历史记录（包含本地图片）")
            return true
        } catch {
            print("❌ 清空历史记录失败: \(error)")
            return false
        }
    }
    
    // MARK: - 统计信息
    
    /// 获取历史记录总数
    /// - Returns: 历史记录数量
    func getHistoryCount() -> Int {
        do {
            let descriptor = FetchDescriptor<HistoryAlbum>()
            return try modelContext.fetchCount(descriptor)
        } catch {
            print("❌ 获取历史记录数量失败: \(error)")
            return 0
        }
    }

    // MARK: - 业务逻辑方法

    /// 检查是否已存在相同的连环画
    /// - Parameter comicId: 连环画ID
    /// - Returns: 是否已存在
    func isComicAlreadyExists(_ comicId: String) -> Bool {
        do {
            let existingAlbum = try fetchHistoryAlbum(by: comicId)
            return existingAlbum != nil
        } catch {
            print("❌ 检查连环画是否存在时出错: \(error)")
            return false
        }
    }

    /// 获取历史记录摘要信息
    /// - Returns: 历史记录摘要
    func getHistorySummary() -> HistorySummary? {
        do {
            let totalCount = getHistoryCount()
            let recentAlbums = try fetchRecentHistoryAlbums(limit: 5)

            return HistorySummary(
                totalCount: totalCount,
                recentAlbums: recentAlbums,
                lastUpdateDate: recentAlbums.first?.creationDate
            )
        } catch {
            print("❌ 获取历史记录摘要失败: \(error)")
            return nil
        }
    }
}

// MARK: - 历史记录摘要数据结构
struct HistorySummary {
    let totalCount: Int
    let recentAlbums: [HistoryAlbum]
    let lastUpdateDate: Date?

    /// 是否有历史记录
    var hasHistory: Bool {
        return totalCount > 0
    }

    /// 最后创建日期（兼容性属性）
    var lastCreationDate: Date? {
        return lastUpdateDate
    }

    /// 最近的标题列表
    var recentTitles: [String] {
        return recentAlbums.map { $0.title }
    }
}
