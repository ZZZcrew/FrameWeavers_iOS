import SwiftUI

/// 连环画结果视图 - 遵循MVVM架构，只负责UI展示
struct ComicResultView: View {
    @Environment(\.dismiss) private var dismiss
    let comicResult: ComicResult
    @State private var viewModel: ComicResultViewModel

    init(comicResult: ComicResult) {
        self.comicResult = comicResult
        self._viewModel = State(wrappedValue: ComicResultViewModel(comicResult: comicResult))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("背景单色")
                    .resizable()
                    .scaledToFill()

                VStack(spacing: 0) {
                    // 连环画内容区域 - 使用书页翻动效果
                    PageCurlView(
                        pages: viewModel.totalPages,
                        currentPage: Binding(
                            get: { viewModel.currentPage },
                            set: { newPage in
                                viewModel.currentPage = newPage
                                viewModel.updateReadingProgress()
                            }
                        )
                    ) { pageIndex in
                        if pageIndex < viewModel.comicResult.panels.count {
                            // 漫画页面
                            ComicPanelView(
                                panel: viewModel.comicResult.panels[pageIndex],
                                geometry: geometry,
                                pageIndex: pageIndex,
                                totalPages: viewModel.totalPages
                            )
                        } else {
                            // 互动问题页面
                            QuestionsView(
                                questions: viewModel.comicResult.finalQuestions,
                                geometry: geometry,
                                pageIndex: pageIndex,
                                totalPages: viewModel.totalPages
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .ignoresSafeArea()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 组件已拆分到独立文件
// ComicPanelView -> FrameWeavers/Views/Components/ComicPanelView.swift
// QuestionsView -> FrameWeavers/Views/Components/QuestionsView.swift
// AsyncImageView -> FrameWeavers/Views/Components/AsyncImageView.swift

// 所有组件已拆分到独立文件中

// MARK: - Preview Data
struct ComicResultView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // 竖屏预览
            ComicResultView(comicResult: ComicResult(
                comicId: "preview-001",
                deviceId: "preview-device",
                title: "小明与阳光的友谊",  // 添加故事标题
                originalVideoTitle: "预览视频",
                creationDate: "2025-07-26",
                panelCount: 3,
                panels: [
                    ComicPanel(
                        panelNumber: 1,
                        imageUrl: "Image1",
                        narration: "在一个阳光明媚的早晨，小明背着书包走在上学的路上。他哼着小曲，心情格外愉快，因为今天是他的生日。"
                    ),
                    ComicPanel(
                        panelNumber: 2,
                        imageUrl: "Image2",
                        narration: "突然，一只可爱的小狗从草丛中跳了出来，摇着尾巴看着小明。小明蹲下身，轻轻抚摸着小狗的头，小狗开心地舔着他的手。"
                    ),
                    ComicPanel(
                        panelNumber: 3,
                        imageUrl: "Image3",
                        narration: "小明决定带着这只小狗一起回家，他想给小狗取个名字叫\"阳光\"。从那天起，阳光成为了小明最好的朋友，他们一起度过了许多快乐的时光。"
                    )
                ],
                finalQuestions: [
                    "你觉得小明为什么会选择\"阳光\"这个名字给小狗？",
                    "如果你是小明，你会如何处理这只突然出现的流浪狗？",
                    "这个故事告诉我们什么关于友谊和善良的道理？"
                ]
            ))
            .previewDisplayName("竖屏预览")
            .previewDevice("iPhone 14")

            // 横屏预览
            ComicResultView(comicResult: ComicResult(
                comicId: "preview-001",
                deviceId: "preview-device",
                title: "小明与阳光的友谊",
                originalVideoTitle: "预览视频",
                creationDate: "2025-07-26",
                panelCount: 3,
                panels: [
                    ComicPanel(
                        panelNumber: 1,
                        imageUrl: "Image1",
                        narration: "在一个阳光明媚的早晨，小明背着书包走在上学的路上。他哼着小曲，心情格外愉快，因为今天是他的生日。"
                    ),
                    ComicPanel(
                        panelNumber: 2,
                        imageUrl: "Image2",
                        narration: "突然，一只可爱的小狗从草丛中跳了出来，摇着尾巴看着小明。小明蹲下身，轻轻抚摸着小狗的头，小狗开心地舔着他的手。"
                    ),
                    ComicPanel(
                        panelNumber: 3,
                        imageUrl: "Image3",
                        narration: "小明决定带着这只小狗一起回家，他想给小狗取个名字叫\"阳光\"。从那天起，阳光成为了小明最好的朋友，他们一起度过了许多快乐的时光。"
                    )
                ],
                finalQuestions: [
                    "你觉得小明为什么会选择\"阳光\"这个名字给小狗？",
                    "如果你是小明，你会如何处理这只突然出现的流浪狗？",
                    "这个故事告诉我们什么关于友谊和善良的道理？"
                ]
            ))
            .previewDisplayName("横屏预览")
            .previewDevice("iPhone 14")
            .previewInterfaceOrientation(.landscapeLeft)

            // 无问题页面预览
            ComicResultView(comicResult: ComicResult(
                comicId: "preview-002",
                deviceId: "preview-device",
                title: "公园里的宁静时光",  // 添加故事标题
                originalVideoTitle: "简单故事",
                creationDate: "2025-07-26",
                panelCount: 1,
                panels: [
                    ComicPanel(
                        panelNumber: 1,
                        imageUrl: "Image4",
                        narration: "这是一个简单的故事，讲述了一个人在公园里散步，享受着美好的天气和宁静的时光。"
                    )
                ],
                finalQuestions: []
            ))
            .previewDisplayName("无问题预览")
            .previewDevice("iPhone 14")
        }
    }
}
