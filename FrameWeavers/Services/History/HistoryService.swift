import Foundation
import SwiftData

// MARK: - 历史记录管理服务

/// 历史画册管理服务
/// 负责历史画册的增删查改操作
class HistoryService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - 保存历史记录
    
    /// 保存新的画册到历史记录
    /// - Parameter comicResult: 要保存的画册结果
    /// - Returns: 是否保存成功
    func saveToHistory(_ comicResult: ComicResult) -> Bool {
        do {
            // 检查是否已存在相同ID的记录
            let existingAlbum = try fetchHistoryAlbum(by: comicResult.comicId)
            if existingAlbum != nil {
                print("⚠️ 历史记录中已存在相同ID的画册: \(comicResult.comicId)")
                return false
            }
            
            // 创建新的历史记录
            let historyAlbum = HistoryAlbum(from: comicResult)
            modelContext.insert(historyAlbum)
            
            try modelContext.save()
            print("✅ 画册已保存到历史记录: \(comicResult.title)")
            return true
            
        } catch {
            print("❌ 保存历史记录失败: \(error)")
            return false
        }
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
            modelContext.delete(historyAlbum)
            try modelContext.save()
            print("✅ 已删除历史画册: \(historyAlbum.title)")
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
            for album in allAlbums {
                modelContext.delete(album)
            }
            try modelContext.save()
            print("✅ 已清空所有历史记录")
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
}
