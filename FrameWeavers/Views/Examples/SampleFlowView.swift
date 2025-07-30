import SwiftUI

/// 示例流程视图 - 复用真实模式的组件
struct SampleFlowView: View {
    @Environment(\.dismiss) private var dismiss
    let comicResult: ComicResult
    @StateObject private var mockViewModel: MockVideoUploadViewModel

    init(comicResult: ComicResult) {
        self.comicResult = comicResult
        self._mockViewModel = StateObject(wrappedValue: MockVideoUploadViewModel(comicResult: comicResult))
    }

    var body: some View {
        NavigationStack {
            SampleSelectStyleView(viewModel: mockViewModel, comicResult: comicResult)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $mockViewModel.shouldNavigateToResults) {
            OpenResultsView(comicResult: comicResult)
        }
        // .navigationBarBackButtonHidden(false)
        // .toolbarBackground(Color.clear, for: .navigationBar)
    }
}

/// 示例专用的风格选择视图 - 使用通用组件
struct SampleSelectStyleView: View {
    @ObservedObject var viewModel: MockVideoUploadViewModel
    let comicResult: ComicResult

    var body: some View {
        StyleSelectionView(
            viewModel: viewModel,
            nextView: AnyView(SampleProcessingView(viewModel: viewModel, comicResult: comicResult))
        )
    }
}

/// 示例专用的处理视图
struct SampleProcessingView: View {
    @ObservedObject var viewModel: MockVideoUploadViewModel
    let comicResult: ComicResult
    @State private var hasNavigated = false  // 防止重复导航

    var body: some View {
        ProcessingView(viewModel: viewModel)
            .onAppear {
                // 开始模拟处理
                viewModel.startMockProcessing()
                // 重置导航状态
                hasNavigated = false
                viewModel.shouldNavigateToResults = false
            }
            .onChange(of: viewModel.uploadStatus) { _, newStatus in
                print("🔄 SampleProcessingView: 状态变化 -> \(newStatus)")
                print("🔄 SampleProcessingView: comicResult 是否存在: \(viewModel.comicResult != nil)")
                print("🔄 SampleProcessingView: hasNavigated: \(hasNavigated)")

                if newStatus == .completed && !hasNavigated {
                    print("✅ SampleProcessingView: 准备导航到结果页面")
                    hasNavigated = true  // 标记已处理，防止重复
                    // 延迟一秒后导航到结果页面
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        print("🚀 SampleProcessingView: 开始导航")
                        print("🚀 SampleProcessingView: 设置 shouldNavigateToResults = true")
                        viewModel.shouldNavigateToResults = true
                        print("🚀 SampleProcessingView: shouldNavigateToResults 已设置为: \(viewModel.shouldNavigateToResults)")
                    }
                } else if newStatus == .completed && hasNavigated {
                    print("⚠️ SampleProcessingView: 已经导航过了，跳过")
                } else if newStatus == .failed {
                    print("❌ SampleProcessingView: 处理失败，不导航")
                }
            }
    }
}

// MARK: - Mock ViewModel
class MockVideoUploadViewModel: VideoUploadViewModel {
    private let targetComicResult: ComicResult?
    private var mockTimer: Timer?

    override init() {
        self.targetComicResult = nil
        super.init()
        // 设置一些模拟视频，但不自动触发状态变化
        self.selectedVideos = [
            URL(string: "file:///mock/sample1.mp4")!,
            URL(string: "file:///mock/sample2.mp4")!
        ]
        // 重置状态，确保从pending开始
        self.uploadStatus = .pending
    }

    init(comicResult: ComicResult) {
        self.targetComicResult = comicResult
        super.init()
    }

    // 重写selectVideos方法，避免自动触发导航
    override func selectVideos(_ urls: [URL]) {
        selectedVideos = urls
        // 不调用super.selectVideos()，避免自动设置shouldNavigateToStyleSelection
    }

    // 重写uploadVideo方法，避免真实的HTTP请求
    override func uploadVideo() {
        // 不调用super.uploadVideo()，直接开始模拟处理
        startMockProcessing()
    }

    func startMockProcessing() {
        uploadStatus = .uploading
        uploadProgress = 0
        errorMessage = nil

        // 模拟上传进度
        mockTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            DispatchQueue.main.async {
                self.uploadProgress += 0.02

                if self.uploadProgress >= 0.3 {
                    self.uploadStatus = .processing
                }

                if self.uploadProgress >= 1.0 {
                    self.uploadProgress = 1.0
                    self.uploadStatus = .completed
                    // 设置目标结果
                    if let result = self.targetComicResult {
                        self.comicResult = result
                    }
                    timer.invalidate()
                    self.mockTimer = nil
                }
            }
        }
    }

    override func reset() {
        // 停止模拟定时器
        mockTimer?.invalidate()
        mockTimer = nil

        super.reset()
        uploadStatus = .pending
        uploadProgress = 0
        errorMessage = nil
    }

    override func cancelUpload() {
        // 停止模拟定时器
        mockTimer?.invalidate()
        mockTimer = nil

        // 不调用super.cancelUpload()，避免网络请求
        uploadStatus = .pending
        uploadProgress = 0
        errorMessage = nil
    }
}

#Preview {
    SampleFlowView(comicResult: ComicResult(
        comicId: "preview-001",
        deviceId: "preview-device",
        title: "小猫的冒险之旅",  // 添加故事标题
        originalVideoTitle: "小猫的冒险之旅",
        creationDate: "2025-07-26",
        panelCount: 4,
        panels: [
            ComicPanel(
                panelNumber: 1,
                imageUrl: "2-第1页",
                narration: "在一个宁静的小镇上，住着一只名叫小花的橘猫。她总是对窗外的世界充满好奇，梦想着有一天能够走出家门，去探索那个未知的大世界。"
            ),
            ComicPanel(
                panelNumber: 2,
                imageUrl: "2-第2页",
                narration: "终于有一天，主人忘记关门了。小花悄悄溜了出去，踏上了她的第一次冒险。街道上的一切都是那么新奇，每一个角落都藏着惊喜。"
            ),
            ComicPanel(
                panelNumber: 3,
                imageUrl: "2-第3页",
                narration: "在公园里，小花遇到了一群友善的流浪猫。他们教会了她如何在野外生存，如何寻找食物，如何躲避危险。小花学会了很多从未想过的技能。"
            ),
            ComicPanel(
                panelNumber: 4,
                imageUrl: "2-第4页",
                narration: "当夜幕降临时，小花想起了温暖的家。她带着满满的回忆和新朋友们的祝福，踏上了回家的路。从此，她既珍惜家的温暖，也不忘记外面世界的精彩。"
            )
        ],
        finalQuestions: [
            "你觉得小花最大的收获是什么？",
            "如果你是小花，你会选择留在外面还是回家？",
            "这个故事告诉我们关于勇气和成长的什么道理？"
        ]
    ))
}
