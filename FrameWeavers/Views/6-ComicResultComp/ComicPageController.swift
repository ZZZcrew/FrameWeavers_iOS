import SwiftUI
import UIKit

/// 3D翻页控制器 - 封装UIPageViewController，符合MVVM架构
struct ComicPageController: UIViewControllerRepresentable {
    let comicResult: ComicResult
    @ObservedObject var viewModel: ComicResultViewModel
    
    // 计算总页数
    private var totalPages: Int {
        comicResult.panels.count + (comicResult.finalQuestions.isEmpty ? 0 : 1)
    }
    
    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageViewController = UIPageViewController(
            transitionStyle: .pageCurl,
            navigationOrientation: .horizontal,
            options: nil
        )
        
        pageViewController.dataSource = context.coordinator
        pageViewController.delegate = context.coordinator
        
        // 设置初始页面
        let initialViewController = context.coordinator.createViewController(for: 0)
        pageViewController.setViewControllers(
            [initialViewController],
            direction: .forward,
            animated: false
        )
        
        return pageViewController
    }
    
    func updateUIViewController(_ pageViewController: UIPageViewController, context: Context) {
        // 处理页面更新
        if let currentVC = pageViewController.viewControllers?.first as? ComicBaseViewController,
           currentVC.pageIndex != viewModel.currentPage {
            
            let direction: UIPageViewController.NavigationDirection = 
                currentVC.pageIndex < viewModel.currentPage ? .forward : .reverse
            let newVC = context.coordinator.createViewController(for: viewModel.currentPage)
            
            pageViewController.setViewControllers(
                [newVC],
                direction: direction,
                animated: true
            )
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: ComicPageController
        
        init(_ parent: ComicPageController) {
            self.parent = parent
        }
        
        // 创建视图控制器
        func createViewController(for index: Int) -> ComicBaseViewController {
            if index < parent.comicResult.panels.count {
                // 漫画页面
                return ComicPanelViewController(
                    panel: parent.comicResult.panels[index],
                    pageIndex: index,
                    totalPages: parent.totalPages,
                    viewModel: parent.viewModel
                )
            } else {
                // 互动问题页面
                return QuestionsViewController(
                    questions: parent.comicResult.finalQuestions,
                    pageIndex: index,
                    totalPages: parent.totalPages,
                    viewModel: parent.viewModel
                )
            }
        }
        
        // MARK: - UIPageViewControllerDataSource
        
        func pageViewController(_ pageViewController: UIPageViewController, 
                              viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let currentVC = viewController as? ComicBaseViewController,
                  currentVC.pageIndex > 0 else {
                return nil
            }
            
            let previousIndex = currentVC.pageIndex - 1
            return createViewController(for: previousIndex)
        }
        
        func pageViewController(_ pageViewController: UIPageViewController, 
                              viewControllerAfter viewController: UIViewController) -> UIViewController? {
            guard let currentVC = viewController as? ComicBaseViewController,
                  currentVC.pageIndex < parent.totalPages - 1 else {
                return nil
            }
            
            let nextIndex = currentVC.pageIndex + 1
            return createViewController(for: nextIndex)
        }
        
        // MARK: - UIPageViewControllerDelegate
        
        func pageViewController(_ pageViewController: UIPageViewController, 
                              didFinishAnimating finished: Bool, 
                              previousViewControllers: [UIViewController], 
                              transitionCompleted completed: Bool) {
            if completed,
               let currentVC = pageViewController.viewControllers?.first as? ComicBaseViewController {
                parent.viewModel.goToPage(currentVC.pageIndex)
            }
        }
    }
}

// MARK: - 基础视图控制器

/// 基础视图控制器 - 提供公共属性和方法
class ComicBaseViewController: UIViewController {
    let pageIndex: Int
    weak var viewModel: ComicResultViewModel?
    
    init(pageIndex: Int, viewModel: ComicResultViewModel) {
        self.pageIndex = pageIndex
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 处理页面点击事件 - 符合MVVM架构，通过ViewModel处理业务逻辑
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        let viewWidth = view.bounds.width
        
        // 通过ViewModel处理点击事件，而不是直接发送通知
        viewModel?.handlePageTap(at: location, viewWidth: viewWidth)
    }
    

    
    /// 添加点击手势的公共方法
    func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(tapGesture)
    }

    /// 通用的 SwiftUI 嵌入方法，消除子类重复代码
    func embedSwiftUIView<Content: View>(_ rootView: Content) {
        let hostingController = UIHostingController(rootView: rootView)
        hostingController.view.backgroundColor = UIColor.clear
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}
