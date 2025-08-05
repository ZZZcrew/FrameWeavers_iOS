import Foundation
import SwiftData

// MARK: - 历史画册数据模型

/// 历史画册SwiftData模型
/// 用于存储用户生成的画册历史记录
@Model
final class HistoryAlbum: Identifiable {
    var id: String
    var title: String
    var originalVideoTitle: String
    var creationDate: Date
    var panelCount: Int
    var comicData: Data // 存储序列化的ComicResult
    var deviceId: String
    var storyStyle: String? // 新增：故事风格
    var thumbnailImageName: String? // 封面图片名称
    
    init(from comicResult: ComicResult, storyStyle: String?) {
        self.id = comicResult.comicId
        self.title = comicResult.title
        self.originalVideoTitle = comicResult.originalVideoTitle
        self.creationDate = ISO8601DateFormatter().date(from: comicResult.creationDate) ?? Date()
        self.panelCount = comicResult.panelCount
        self.deviceId = comicResult.deviceId
        self.storyStyle = storyStyle // 保存故事风格
        self.thumbnailImageName = comicResult.panels.first?.imageUrl
        
        // 序列化ComicResult为Data
        do {
            self.comicData = try JSONEncoder().encode(comicResult)
        } catch {
            print("❌ 序列化ComicResult失败: \(error)")
            self.comicData = Data()
        }
    }
    
    /// 从存储的数据恢复ComicResult
    func toComicResult() -> ComicResult? {
        do {
            return try JSONDecoder().decode(ComicResult.self, from: comicData)
        } catch {
            print("❌ 反序列化ComicResult失败: \(error)")
            return nil
        }
    }
}

// MARK: - 历史画册显示模型

/// 用于在UI中显示的历史画册数据
struct HistoryAlbumDisplayModel: Identifiable {
    let id: String
    let title: String
    let description: String
    let coverImage: String?
    let creationDate: Date
    let storyStyle: String? // 新增：故事风格
    let comicResult: ComicResult?
    
    init(from historyAlbum: HistoryAlbum) {
        self.id = historyAlbum.id
        self.title = historyAlbum.title
        let styleText = historyAlbum.storyStyle ?? "未知风格"
        self.description = "\(historyAlbum.panelCount)页 · \(styleText) · \(DateFormatter.shortDate.string(from: historyAlbum.creationDate))"
        self.coverImage = historyAlbum.thumbnailImageName
        self.creationDate = historyAlbum.creationDate
        self.storyStyle = historyAlbum.storyStyle
        self.comicResult = historyAlbum.toComicResult()
    }
}

// MARK: - 扩展

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
}
