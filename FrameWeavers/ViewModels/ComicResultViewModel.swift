import SwiftUI
import Combine

/// 连环画结果视图模型
/// 负责管理连环画阅读的业务逻辑和状态
@Observable
class ComicResultViewModel {
    // MARK: - Published Properties
    var currentPage: Int = 0
    var isNavigationVisible: Bool = true
    var readingProgress: Double = 0.0
    var isAnimating: Bool = false

    // MARK: - Properties
    let comicResult: ComicResult
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
        setupNotificationObservers()
    }

    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Public Methods
    
    /// 跳转到下一页
    func nextPage() {
        guard !isLastPage else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentPage += 1
            updateReadingProgress()
        }
    }
    
    /// 跳转到上一页
    func previousPage() {
        guard !isFirstPage else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentPage -= 1
            updateReadingProgress()
        }
    }
    
    /// 跳转到指定页面
    /// - Parameter page: 目标页面索引
    func goToPage(_ page: Int) {
        guard page >= 0 && page < totalPages else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentPage = page
            updateReadingProgress()
        }
    }
    
    /// 切换导航栏可见性
    func toggleNavigationVisibility() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isNavigationVisible.toggle()
        }
    }
    
    /// 更新阅读进度（公开方法）
    func updateReadingProgress() {
        guard totalPages > 0 else {
            readingProgress = 0.0
            return
        }
        readingProgress = Double(currentPage + 1) / Double(totalPages)
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

    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: .comicPageNext)
            .sink { [weak self] _ in
                self?.nextPage()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .comicPagePrevious)
            .sink { [weak self] _ in
                self?.previousPage()
            }
            .store(in: &cancellables)
    }


}

// MARK: - Supporting Types

extension ComicResultViewModel {
    enum PageType {
        case comic(ComicPanel)
        case questions([String])
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let comicPageNext = Notification.Name("comicPageNext")
    static let comicPagePrevious = Notification.Name("comicPagePrevious")
}

// MARK: - Preview Support

extension ComicResultViewModel {
    static func preview() -> ComicResultViewModel {
        let mockResult = ComicResult(
            comicId: "preview-001",
            deviceId: "preview-device",
            title: "预览连环画",
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
