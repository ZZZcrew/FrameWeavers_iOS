import SwiftUI
import Combine

/// 连环画结果视图模型
/// 负责管理连环画阅读的业务逻辑和状态
class ComicResultViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentPage: Int = 0
    @Published var isNavigationVisible: Bool = true
    @Published var readingProgress: Double = 0.0
    
    // MARK: - Private Properties
    private let comicResult: ComicResult
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    /// 总页数（包括问题页）
    var totalPages: Int {
        comicResult.panels.count + (comicResult.finalQuestions.isEmpty ? 0 : 1)
    }
    
    /// 是否为最后一页
    var isLastPage: Bool {
        currentPage >= totalPages - 1
    }
    
    /// 是否为第一页
    var isFirstPage: Bool {
        currentPage <= 0
    }
    
    /// 当前页面类型
    var currentPageType: PageType {
        if currentPage < comicResult.panels.count {
            return .comic(comicResult.panels[currentPage])
        } else {
            return .questions(comicResult.finalQuestions)
        }
    }
    
    /// 阅读进度百分比
    var progressPercentage: String {
        let percentage = Int(readingProgress * 100)
        return "\(percentage)%"
    }
    
    // MARK: - Initialization
    
    init(comicResult: ComicResult) {
        self.comicResult = comicResult
        updateReadingProgress()
        setupCombineBindings()
    }
    
    // MARK: - Combine响应式绑定
    
    /// 设置Combine响应式数据流
    private func setupCombineBindings() {
        // 响应式更新阅读进度
        $currentPage
            .map { [weak self] page in
                guard let self = self, self.totalPages > 0 else { return 0.0 }
                return Double(page + 1) / Double(self.totalPages)
            }
            .assign(to: &$readingProgress)
    }
    
    // MARK: - Public Methods
    
    /// 跳转到下一页
    func nextPage() {
        guard !isLastPage else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentPage += 1
            // updateReadingProgress() - 现在由Combine自动响应更新
        }
    }
    
    /// 跳转到上一页
    func previousPage() {
        guard !isFirstPage else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentPage -= 1
            // updateReadingProgress() - 现在由Combine自动响应更新
        }
    }
    
    /// 跳转到指定页面
    /// - Parameter page: 目标页面索引
    func goToPage(_ page: Int) {
        guard page >= 0 && page < totalPages else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentPage = page
            // updateReadingProgress() - 现在由Combine自动响应更新
        }
    }
    
    /// 切换导航栏可见性
    func toggleNavigationVisibility() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isNavigationVisible.toggle()
        }
    }
    
    /// 处理页面点击事件
    /// - Parameter location: 点击位置
    /// - Parameter viewWidth: 视图宽度
    func handlePageTap(at location: CGPoint, viewWidth: CGFloat) {
        // 点击左侧区域 - 向前翻页
        if location.x < viewWidth * 0.3 {
            previousPage()
        }
        // 点击右侧区域 - 向后翻页
        else if location.x > viewWidth * 0.7 {
            nextPage()
        }
        // 点击中间区域 - 切换导航栏显示
        else {
            toggleNavigationVisibility()
        }
    }
    
    // MARK: - Private Methods

    private func updateReadingProgress() {
        guard totalPages > 0 else {
            readingProgress = 0.0
            return
        }
        
        readingProgress = Double(currentPage + 1) / Double(totalPages)
    }
}

// MARK: - Supporting Types

extension ComicResultViewModel {
    enum PageType {
        case comic(ComicPanel)
        case questions([String])
    }
}

// MARK: - Preview Support

extension ComicResultViewModel {
    static func preview() -> ComicResultViewModel {
        let mockResult = ComicResult(
            comicId: "preview-001",
            deviceId: "preview-device",
            title: "预览连环画",
            summary: "这是一个用于预览的连环画故事摘要",
            originalVideoTitle: "预览视频",
            creationDate: "2025-07-30",
            panelCount: 3,
            panels: [
                ComicPanel(panelNumber: 1, imageUrl: "Image1", narration: "第一页内容"),
                ComicPanel(panelNumber: 2, imageUrl: "Image2", narration: "第二页内容"),
                ComicPanel(panelNumber: 3, imageUrl: "Image3", narration: "第三页内容")
            ],
            finalQuestions: ["问题1", "问题2", "问题3"]
        )
        return ComicResultViewModel(comicResult: mockResult)
    }
}
