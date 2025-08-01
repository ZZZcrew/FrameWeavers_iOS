import Foundation
import SwiftData
import Combine

// MARK: - 历史记录管理服务

/// 历史记录管理服务
/// 负责协调历史记录的保存、管理和业务逻辑处理
/// 封装HistoryService的使用，提供更高级的历史记录管理功能
class HistoryManagementService {
    
    // MARK: - 属性
    
    private let historyService: HistoryService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初始化
    
    /// 初始化历史记录管理服务
    /// - Parameter modelContext: SwiftData模型上下文
    init(modelContext: ModelContext) {
        self.historyService = HistoryService(modelContext: modelContext)
    }
    
    // MARK: - 历史记录保存
    
    /// 保存连环画结果到历史记录
    /// - Parameters:
    ///   - comicResult: 要保存的连环画结果
    ///   - completion: 完成回调，返回是否保存成功
    func saveComicToHistory(
        _ comicResult: ComicResult,
        completion: @escaping (Bool) -> Void = { _ in }
    ) {
        // 在后台队列执行保存操作
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            let success = self.historyService.saveToHistory(comicResult)
            
            DispatchQueue.main.async {
                if success {
                    print("✅ 连环画已成功保存到历史记录: \(comicResult.title)")
                } else {
                    print("❌ 保存连环画到历史记录失败")
                }
                completion(success)
            }
        }
    }
    
    /// 异步保存连环画结果到历史记录
    /// - Parameter comicResult: 要保存的连环画结果
    /// - Returns: 是否保存成功
    func saveComicToHistory(_ comicResult: ComicResult) async -> Bool {
        return await withCheckedContinuation { continuation in
            saveComicToHistory(comicResult) { success in
                continuation.resume(returning: success)
            }
        }
    }
    
    // MARK: - 历史记录查询
    
    /// 获取所有历史记录
    /// - Returns: 历史记录列表
    func getAllHistoryAlbums() throws -> [HistoryAlbum] {
        return try historyService.fetchAllHistoryAlbums()
    }
    
    /// 获取最近的历史记录
    /// - Parameter limit: 限制数量
    /// - Returns: 最近的历史记录列表
    func getRecentHistoryAlbums(limit: Int = 10) throws -> [HistoryAlbum] {
        return try historyService.fetchRecentHistoryAlbums(limit: limit)
    }
    
    /// 根据ID获取历史记录
    /// - Parameter id: 记录ID
    /// - Returns: 历史记录，如果不存在则返回nil
    func getHistoryAlbum(by id: String) throws -> HistoryAlbum? {
        return try historyService.fetchHistoryAlbum(by: id)
    }
    
    // MARK: - 历史记录删除
    
    /// 删除历史记录
    /// - Parameter historyAlbum: 要删除的历史记录
    /// - Returns: 是否删除成功
    func deleteHistoryAlbum(_ historyAlbum: HistoryAlbum) -> Bool {
        return historyService.deleteHistoryAlbum(historyAlbum)
    }
    
    /// 根据ID删除历史记录
    /// - Parameter id: 记录ID
    /// - Returns: 是否删除成功
    func deleteHistoryAlbum(by id: String) -> Bool {
        return historyService.deleteHistoryAlbum(by: id)
    }
    
    /// 清空所有历史记录
    /// - Returns: 是否清空成功
    func clearAllHistory() -> Bool {
        return historyService.clearAllHistory()
    }
    
    // MARK: - 统计信息
    
    /// 获取历史记录总数
    /// - Returns: 历史记录数量
    func getHistoryCount() -> Int {
        return historyService.getHistoryCount()
    }
    
    // MARK: - 业务逻辑方法
    
    /// 检查是否已存在相同的连环画
    /// - Parameter comicId: 连环画ID
    /// - Returns: 是否已存在
    func isComicAlreadyExists(_ comicId: String) -> Bool {
        do {
            let existingAlbum = try historyService.fetchHistoryAlbum(by: comicId)
            return existingAlbum != nil
        } catch {
            print("❌ 检查连环画是否存在时出错: \(error)")
            return false
        }
    }
    
    /// 获取历史记录摘要信息
    /// - Returns: 历史记录摘要
    func getHistorySummary() -> HistorySummary {
        let totalCount = getHistoryCount()
        
        do {
            let recentAlbums = try getRecentHistoryAlbums(limit: 5)
            let lastCreationDate = recentAlbums.first?.creationDate
            
            return HistorySummary(
                totalCount: totalCount,
                lastCreationDate: lastCreationDate,
                recentTitles: recentAlbums.map { $0.title }
            )
        } catch {
            print("❌ 获取历史记录摘要失败: \(error)")
            return HistorySummary(
                totalCount: totalCount,
                lastCreationDate: nil,
                recentTitles: []
            )
        }
    }
}

// MARK: - 历史记录摘要模型

/// 历史记录摘要信息
struct HistorySummary {
    let totalCount: Int
    let lastCreationDate: Date?
    let recentTitles: [String]
    
    /// 是否有历史记录
    var hasHistory: Bool {
        return totalCount > 0
    }
    
    /// 格式化的最后创建时间
    var formattedLastCreationDate: String? {
        guard let lastCreationDate = lastCreationDate else { return nil }
        return DateFormatter.shortDate.string(from: lastCreationDate)
    }
}
