import SwiftUI
import UIKit

/// 单个漫画页面视图控制器 - 符合MVVM架构
class ComicPanelViewController: ComicBaseViewController {
    let panel: ComicPanel
    let totalPages: Int
    
    init(panel: ComicPanel, pageIndex: Int, totalPages: Int, geometry: GeometryProxy, viewModel: ComicResultViewModel) {
        self.panel = panel
        self.totalPages = totalPages
        super.init(pageIndex: pageIndex, geometry: geometry, viewModel: viewModel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    private func setupView() {
        // 设置背景
        setupBackgroundImage()
        
        // 创建SwiftUI视图并包装
        let hostingController = UIHostingController(
            rootView: ComicPanelView(
                panel: panel,
                geometry: geometry,
                pageIndex: pageIndex,
                totalPages: totalPages
            )
        )
        
        // 设置透明背景
        hostingController.view.backgroundColor = UIColor.clear
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        // 设置约束
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        // 添加点击手势
        setupTapGesture()
    }
}

/// 互动问题页面视图控制器 - 符合MVVM架构
class QuestionsViewController: ComicBaseViewController {
    let questions: [String]
    let totalPages: Int
    
    init(questions: [String], pageIndex: Int, totalPages: Int, geometry: GeometryProxy, viewModel: ComicResultViewModel) {
        self.questions = questions
        self.totalPages = totalPages
        super.init(pageIndex: pageIndex, geometry: geometry, viewModel: viewModel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    private func setupView() {
        // 设置背景
        setupBackgroundImage()
        
        // 创建SwiftUI视图并包装
        let hostingController = UIHostingController(
            rootView: QuestionsView(
                questions: questions,
                geometry: geometry,
                pageIndex: pageIndex,
                totalPages: totalPages
            )
        )
        
        // 设置透明背景
        hostingController.view.backgroundColor = UIColor.clear
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        // 设置约束
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        // 添加点击手势
        setupTapGesture()
    }
}
