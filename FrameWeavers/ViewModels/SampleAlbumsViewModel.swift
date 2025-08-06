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
                        narration: "有些心跳，与生俱来，随山川共鸣；有些心跳，是代码谱写的未来序曲。这里，是涪陵，一个能听见两种心跳的地方。"
                    ),
                    ComicPanel(
                        panelNumber: 2,
                        imageUrl: "key_frame_01_styled",
                        narration: "未来并非遥远彼岸，而是眼前这条通透、洁净、充满无限可能的走廊。"
                    ),
                    ComicPanel(
                        panelNumber: 3,
                        imageUrl: "key_frame_02_styled",
                        narration: "然而，通向未来的路，始终踏在古老的土地上。每一级栈道，都记得风与时间的叮咛。"
                    ),
                    ComicPanel(
                        panelNumber: 4,
                        imageUrl: "key_frame_03_styled",
                        narration: "在这里，光阴似乎放慢了脚步，让千年的亭台，与璀璨的星河，完成一场无声的对望。"
                    ),
                    ComicPanel(
                        panelNumber: 5,
                        imageUrl: "key_frame_04_styled",
                        narration: "栈道静默，峡谷无言。它们仿佛在等待，等待一颗敢于探索未知的心，前来唤醒沉睡的诗篇。"
                    ),
                    ComicPanel(
                        panelNumber: 6,
                        imageUrl: "key_frame_05_styled",
                        narration: "每一块石板，每一处飞檐，都承载着文化的重量，是这片土地不曾磨灭的灵魂印记。"
                    ),
                    ComicPanel(
                        panelNumber: 7,
                        imageUrl: "key_frame_06_styled",
                        narration: "它静静矗立，看云卷云舒，如同一只大山的眼睛，淡然见证着身边发生的一切奇迹。"
                    ),
                    ComicPanel(
                        panelNumber: 8,
                        imageUrl: "key_frame_07_styled",
                        narration: "而另一双眼睛，正凝视着数据的深渊。在这里，人类的智慧，正试图赋予冰冷的机器以温度。"
                    ),
                    ComicPanel(
                        panelNumber: 9,
                        imageUrl: "key_frame_08_styled",
                        narration: "出行的定义被重新改写。古老的山峦之间，流淌着无声、高效的未来脉络。"
                    ),
                    ComicPanel(
                        panelNumber: 10,
                        imageUrl: "key_frame_09_styled",
                        narration: "当科技的精度，遇见生活的温度，一杯咖啡便有了灵魂。这是代码的匠心，也是数据的温情。"
                    ),
                    ComicPanel(
                        panelNumber: 11,
                        imageUrl: "key_frame_10_styled",
                        narration: "而自然，从不吝啬它的奇迹，用一场划破夜空的流星雨，回应着人类关于明天的梦想。"
                    ),
                    ComicPanel(
                        panelNumber: 12,
                        imageUrl: "key_frame_11_styled",
                        narration: "灯火，是人类在大地上点亮的繁星，与天上的银河遥相呼应，共同守护着这片土地的安宁。"
                    ),
                    ComicPanel(
                        panelNumber: 13,
                        imageUrl: "key_frame_12_styled",
                        narration: "月光之下，城市的轮廓变得温柔。古老的传说与未来的诗篇，在此刻无声地交融。"
                    ),
                    ComicPanel(
                        panelNumber: 14,
                        imageUrl: "key_frame_13_styled",
                        narration: "每一条蜿蜒的道路，都是一次连接，连接着城市与山野，也连接着过去与现在。"
                    ),
                    ComicPanel(
                        panelNumber: 15,
                        imageUrl: "key_frame_14_styled",
                        narration: "我们飞越雪山之巅，俯瞰大地的壮丽。人类探索的边界，早已超越了地平线。"
                    ),
                    ComicPanel(
                        panelNumber: 16,
                        imageUrl: "key_frame_15_styled",
                        narration: "但我们从未忘记，生命最初的形态。当一株新绿，破土于芯片之上，这，就是对未来最好的答案：生长，共生。"
                    ),
                    ComicPanel(
                        panelNumber: 17,
                        imageUrl: "key_frame_16_styled",
                        narration: "建筑不再是自然的闯入者，而是森林的一部分。这是科技对生命，最谦卑的致敬。"
                    ),
                    ComicPanel(
                        panelNumber: 18,
                        imageUrl: "key_frame_17_styled",
                        narration: "它们是没有体温的伙伴，却能读懂你的心事，陪伴你探索世界的每一个角落。"
                    ),
                    ComicPanel(
                        panelNumber: 19,
                        imageUrl: "key_frame_18_styled",
                        narration: "最终，一切的宏大叙事，都回归到这间小小的咖啡馆，回归到这一杯手冲的专注与醇香。"
                    ),
                    ComicPanel(
                        panelNumber: 20,
                        imageUrl: "key_frame_19_styled",
                        narration: "飞向云端，也扎根大地。芯跳不息，关于这里的故事，才刚刚开始。"
                    )
                ],
                finalQuestions: [
                    "AI咖啡馆里，你更期待窗外的风景，还是手中的咖啡？",
                    "你认为AI冲煮的咖啡，真的能拥有“灵魂”吗？",
                    "要实现科技与自然的和谐，关键在于什么？"
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
