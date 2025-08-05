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
            title: "山魂觉醒：AI咖啡师的千年之约",
            description: "在重庆涪陵的千年山魂中，一个关于未来的约定悄然开启。当冰冷的AI代码开始学习冲煮一杯有温度的咖啡时，科技便化作了传承文化的崭新方式，与壮丽山河达成了和谐共鸣，谱写出人、自然与科技共生的新篇章。",
            coverImage: "key_frame_00_styled",
            comicResult: ComicResult(
                comicId: "sample-001",
                deviceId: "sample-device",
                title: "山魂觉醒：AI咖啡师的千年之约",
                summary: "在重庆涪陵的千年山魂中，一个关于未来的约定悄然开启。当冰冷的AI代码开始学习冲煮一杯有温度的咖啡时，科技便化作了传承文化的崭新方式，与壮丽山河达成了和谐共鸣，谱写出人、自然与科技共生的新篇章。",
                originalVideoTitle: "山魂觉醒：AI咖啡师的千年之约",
                creationDate: "2025-08-05",
                panelCount: 20,
                panels: [
                    ComicPanel(
                        panelNumber: 1,
                        imageUrl: "key_frame_00_styled",
                        narration: "传说，在这座香气弥漫的山城，古老的群山与未来立下了一个约定。"
                    ),
                    ComicPanel(
                        panelNumber: 2,
                        imageUrl: "key_frame_01_styled",
                        narration: "而在时间的长河深处，一个崭新的世界正在被悄然构建，它不源于泥土，而生于光与代码。"
                    ),
                    ComicPanel(
                        panelNumber: 3,
                        imageUrl: "key_frame_02_styled",
                        narration: "这里，日光信守着千年的诺言，水色青翠，染透了历史的衣褶。"
                    ),
                    ComicPanel(
                        panelNumber: 4,
                        imageUrl: "key_frame_03_styled",
                        narration: "每一条索道，都像一首被传唱的童谣，载着人们穿越云海，触碰时间的脉络。"
                    ),
                    ComicPanel(
                        panelNumber: 5,
                        imageUrl: "key_frame_04_styled",
                        narration: "当夜幕降临，星辰是唯一的见证者，看这片土地如何在静默中，孕育着一场变革。"
                    ),
                    ComicPanel(
                        panelNumber: 6,
                        imageUrl: "key_frame_05_styled",
                        narration: "文化的传承，从未被遗忘，它化作基石，为即将到来的新生事物，铺就最坚实厚重的道路。"
                    ),
                    ComicPanel(
                        panelNumber: 7,
                        imageUrl: "key_frame_06_styled",
                        narration: "于是，想象力被赋予了形态，思想的电波绘成了穿越时光的云图。"
                    ),
                    ComicPanel(
                        panelNumber: 8,
                        imageUrl: "key_frame_07_styled",
                        narration: "古老的栈道依然蜿蜒，它见证了过去，也引领着抵达未来的方向。"
                    ),
                    ComicPanel(
                        panelNumber: 9,
                        imageUrl: "key_frame_08_styled",
                        narration: "传统的轮廓依然清晰，是这片土地永恒的注脚，也是新故事的序章。"
                    ),
                    ComicPanel(
                        panelNumber: 10,
                        imageUrl: "key_frame_09_styled",
                        narration: "在这宁静之下，一种截然不同的心跳声，开始与古老的山峦共鸣。"
                    ),
                    ComicPanel(
                        panelNumber: 11,
                        imageUrl: "key_frame_10_styled",
                        narration: "终于，在极致洁净的空间里，一个融合了科技与温度的造物，悄然诞生。"
                    ),
                    ComicPanel(
                        panelNumber: 12,
                        imageUrl: "key_frame_11_styled",
                        narration: "它用精密的计算，复刻着手冲的艺术；用不知疲倦的专注，延续着咖啡的灵魂。"
                    ),
                    ComicPanel(
                        panelNumber: 13,
                        imageUrl: "key_frame_12_styled",
                        narration: "这便是约定的答案——当AI开始冲煮第一杯咖啡，千年的山魂便注入了全新的生命。"
                    ),
                    ComicPanel(
                        panelNumber: 14,
                        imageUrl: "key_frame_13_styled",
                        narration: "夜色中，咖啡馆的灯光，成为了山谷里最温暖的信标，等待着与每一颗探索的心同频共振。"
                    ),
                    ComicPanel(
                        panelNumber: 15,
                        imageUrl: "key_frame_14_styled",
                        narration: "此刻，宇宙的壮丽与科技的奇迹在这片峡谷中交汇，谱写出新的乐章。"
                    ),
                    ComicPanel(
                        panelNumber: 16,
                        imageUrl: "key_frame_15_styled",
                        narration: "“六小龙”的传说，伴着月光，化作一双翅膀，飞翔在涪陵大地的上空。"
                    ),
                    ComicPanel(
                        panelNumber: 17,
                        imageUrl: "key_frame_16_styled",
                        narration: "捧起这杯咖啡，便是捧起了整片山河。你的心跳，将与这片土地的脉搏同频。"
                    ),
                    ComicPanel(
                        panelNumber: 18,
                        imageUrl: "key_frame_17_styled",
                        narration: "从云端航线到林间小径，过去与未来在此交织，所有的足迹都将留下印记。"
                    ),
                    ComicPanel(
                        panelNumber: 19,
                        imageUrl: "key_frame_18_styled",
                        narration: "山川发出最诚挚的邀请，炊烟与云雾，是写给世界最动人的诗篇。"
                    ),
                    ComicPanel(
                        panelNumber: 20,
                        imageUrl: "key_frame_19_styled",
                        narration: "前方的路已经清晰——那是一条通往未来的栈道，它连接的不是两座山，而是传统与新生。"
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
                summary: "一个关于旅行、发现和成长的美丽故事，记录了在路上遇见的风景、人情和那些温暖的瞬间。",
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
