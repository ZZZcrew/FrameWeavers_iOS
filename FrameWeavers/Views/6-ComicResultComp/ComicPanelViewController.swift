import SwiftUI
import UIKit

/// 单个漫画页面视图控制器 - 符合MVVM架构
class ComicPanelViewController: ComicBaseViewController {
    let panel: ComicPanel
    let totalPages: Int
    
    init(panel: ComicPanel, pageIndex: Int, totalPages: Int, viewModel: ComicResultViewModel) {
        self.panel = panel
        self.totalPages = totalPages
        super.init(pageIndex: pageIndex, viewModel: viewModel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    private func setupView() {
        // 创建SwiftUI视图并通用嵌入
        embedSwiftUIView(
            ComicPanelView(
                panel: panel,
                pageIndex: pageIndex,
                totalPages: totalPages
            )
        )

        // 添加点击手势
        setupTapGesture()
    }
}

/// 互动问题页面视图控制器 - 符合MVVM架构
class QuestionsViewController: ComicBaseViewController {
    let questions: [String]
    let totalPages: Int
    
    init(questions: [String], pageIndex: Int, totalPages: Int, viewModel: ComicResultViewModel) {
        self.questions = questions
        self.totalPages = totalPages
        super.init(pageIndex: pageIndex, viewModel: viewModel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    private func setupView() {
        // 创建SwiftUI视图并通用嵌入
        embedSwiftUIView(
            QuestionsView(
                questions: questions,
                pageIndex: pageIndex,
                totalPages: totalPages
            )
        )

        // 添加点击手势
        setupTapGesture()
    }
}
