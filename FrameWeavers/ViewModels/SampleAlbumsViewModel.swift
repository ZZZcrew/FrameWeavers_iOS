import Foundation
import SwiftUI
import SwiftData
import Combine

/// 示例画册视图模型
/// 负责管理示例画册和历史记录的业务逻辑
class SampleAlbumsViewModel: ObservableObject {
    @Published var historyAlbums: [HistoryAlbum] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var historyService: HistoryService?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 示例画册数据
    let sampleAlbums: [SampleAlbum] = [
        SampleAlbum(
            id: "sample-001",
            title: "时光里的温暖记忆",
            description: "一个关于家庭温情的美好故事",
            coverImage: "封面",
            comicResult: ComicResult(
                comicId: "sample-001",
                deviceId: "sample-device",
                title: "时光里的温暖记忆",
                originalVideoTitle: "时光里的温暖记忆",
                creationDate: "2025-07-26",
                panelCount: 3,
                panels: [
                    ComicPanel(
                        panelNumber: 1,
                        imageUrl: "1-第1页",
                        narration: "阳光透过窗棂洒在桌案上，奶奶正在为即将远行的孙女准备行囊。每一件衣物都被细心地叠好，每一样物品都承载着满满的爱意。"
                    ),
                    ComicPanel(
                        panelNumber: 2,
                        imageUrl: "1-第2页",
                        narration: "小女孩依偎在奶奶身边，听着那些讲了无数遍却永远不厌倦的故事。奶奶温暖的怀抱，是这世界上最安全的港湾。"
                    ),
                    ComicPanel(
                        panelNumber: 3,
                        imageUrl: "1-第3页",
                        narration: "离别的时刻终于到来，奶奶将一个小小的香囊塞进孙女的手中。'无论走到哪里，都要记得回家的路。'奶奶的话语如春风般温柔。"
                    )
                ],
                finalQuestions: [
                    "你还记得奶奶的味道吗？",
                    "那个香囊现在还在吗？",
                    "你想对奶奶说什么？"
                ]
            )
        ),
        SampleAlbum(
            id: "sample-002",
            title: "小猫的冒险之旅",
            description: "一只勇敢小猫的奇妙探险",
            coverImage: "2-第1页",
            comicResult: ComicResult(
                comicId: "sample-002",
                deviceId: "sample-device",
                title: "小猫的冒险之旅",
                originalVideoTitle: "小猫的冒险之旅",
                creationDate: "2025-07-26",
                panelCount: 4,
                panels: [
                    ComicPanel(
                        panelNumber: 1,
                        imageUrl: "2-第1页",
                        narration: "有些旅程，从一张牌、一个无关紧要的输赢开始。窗外的世界向后飞驰，而前方的未知，在笑声中悄然展开。"
                    ),
                    ComicPanel(
                        panelNumber: 2,
                        imageUrl: "2-第2页",
                        narration: "她曾以为，旅途的意义在于抵达。直到她捧着那束向日葵，在陌生的绿意前停下脚步，才发现，有些风景，是为了让你与自己重逢。"
                    ),
                    ComicPanel(
                        panelNumber: 3,
                        imageUrl: "2-第3页",
                        narration: "而那些不期而遇的浪漫，就像街角突然出现的玫瑰，提醒着她，这世界总有人在笨拙而热烈地爱着你。"
                    ),
                    ComicPanel(
                        panelNumber: 4,
                        imageUrl: "2-第4页",
                        narration: "记忆里最滚烫的，往往是街头巷尾的烟火气。一串烤红薯的香甜，和朋友分享的蓝色围巾，共同织就了那个回不去的午后。"
                    )
                ],
                finalQuestions: [
                    "旅行中最难忘的是什么？",
                    "你会为了什么而停下脚步？",
                    "什么让你感到最温暖？"
                ]
            )
        ),
        SampleAlbum(
            id: "sample-003",
            title: "城市夜景",
            description: "繁华都市的璀璨夜晚",
            coverImage: "封面",
            comicResult: nil
        ),
        SampleAlbum(
            id: "sample-004",
            title: "海边日落",
            description: "宁静海滩的美丽黄昏",
            coverImage: "封面",
            comicResult: nil
        )
    ]
    
    // MARK: - 计算属性
    
    /// 历史记录数量
    var historyCount: Int {
        historyAlbums.count
    }
    
    /// 是否有历史记录
    var hasHistory: Bool {
        !historyAlbums.isEmpty
    }
    
    // MARK: - 初始化
    
    /// 设置历史记录服务
    /// - Parameter modelContext: SwiftData模型上下文
    func setHistoryService(modelContext: ModelContext) {
        self.historyService = HistoryService(modelContext: modelContext)
        loadHistoryAlbums()
    }
    
    // MARK: - 历史记录管理
    
    /// 加载历史记录
    func loadHistoryAlbums() {
        guard let historyService = historyService else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let albums = try historyService.fetchAllHistoryAlbums()
            DispatchQueue.main.async {
                self.historyAlbums = albums
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "加载历史记录失败: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    /// 删除历史画册
    /// - Parameter historyAlbum: 要删除的历史画册
    func deleteHistoryAlbum(_ historyAlbum: HistoryAlbum) {
        guard let historyService = historyService else { return }
        
        let success = historyService.deleteHistoryAlbum(historyAlbum)
        if success {
            // 从本地数组中移除
            historyAlbums.removeAll { $0.id == historyAlbum.id }
            print("✅ 已删除历史画册: \(historyAlbum.title)")
        } else {
            errorMessage = "删除失败"
        }
    }
    
    /// 批量删除历史画册
    /// - Parameter offsets: 要删除的索引集合
    func deleteHistoryAlbums(at offsets: IndexSet) {
        guard let historyService = historyService else { return }
        
        let albumsToDelete = offsets.map { historyAlbums[$0] }
        
        for album in albumsToDelete {
            let success = historyService.deleteHistoryAlbum(album)
            if success {
                historyAlbums.removeAll { $0.id == album.id }
                print("✅ 已删除历史画册: \(album.title)")
            }
        }
    }
    
    /// 清空所有历史记录
    func clearAllHistory() {
        guard let historyService = historyService else { return }
        
        let success = historyService.clearAllHistory()
        if success {
            historyAlbums.removeAll()
            print("✅ 已清空所有历史记录")
        } else {
            errorMessage = "清空失败"
        }
    }
}

// MARK: - 示例画册数据模型

/// 示例画册数据模型
struct SampleAlbum: Identifiable {
    let id: String
    let title: String
    let description: String
    let coverImage: String
    let comicResult: ComicResult?
}
