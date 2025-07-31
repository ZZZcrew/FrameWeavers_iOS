import SwiftUI
import UIKit

/// 页面视图控制器 - 用于包装每个页面并提供索引信息
class PageViewController: UIViewController {
    let pageIndex: Int

    init(index: Int) {
        self.pageIndex = index
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// 书页翻动视图 - 使用 UIPageViewController 实现真实的书页翻动效果
struct PageCurlView<Content: View>: UIViewControllerRepresentable {
    let pages: Int
    @Binding var currentPage: Int
    let content: (Int) -> Content
    
    init(pages: Int, currentPage: Binding<Int>, @ViewBuilder content: @escaping (Int) -> Content) {
        self.pages = pages
        self._currentPage = currentPage
        self.content = content
    }
    
    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageViewController = UIPageViewController(
            transitionStyle: .pageCurl,
            navigationOrientation: .horizontal,
            options: [UIPageViewController.OptionsKey.spineLocation: NSNumber(value: UIPageViewController.SpineLocation.min.rawValue)]
        )

        pageViewController.dataSource = context.coordinator
        pageViewController.delegate = context.coordinator

        // 设置初始页面
        if pages > 0 {
            let initialViewController = context.coordinator.viewController(for: currentPage)
            pageViewController.setViewControllers([initialViewController], direction: .forward, animated: false)
        }

        return pageViewController
    }
    
    func updateUIViewController(_ uiViewController: UIPageViewController, context: Context) {
        // 当 currentPage 从外部更新时，同步 UIPageViewController
        guard let currentViewController = uiViewController.viewControllers?.first,
              let currentIndex = context.coordinator.index(of: currentViewController),
              currentIndex != currentPage else { return }
        
        let targetViewController = context.coordinator.viewController(for: currentPage)
        let direction: UIPageViewController.NavigationDirection = currentPage > currentIndex ? .forward : .reverse
        
        uiViewController.setViewControllers([targetViewController], direction: direction, animated: true)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        let parent: PageCurlView
        private var viewControllers: [PageViewController] = []

        init(_ parent: PageCurlView) {
            self.parent = parent
            super.init()
            setupViewControllers()
        }

        private func setupViewControllers() {
            viewControllers = (0..<parent.pages).map { index in
                let pageVC = PageViewController(index: index)
                let hostingController = UIHostingController(rootView: parent.content(index))
                hostingController.view.backgroundColor = UIColor.clear
                pageVC.addChild(hostingController)
                pageVC.view.addSubview(hostingController.view)
                hostingController.view.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    hostingController.view.topAnchor.constraint(equalTo: pageVC.view.topAnchor),
                    hostingController.view.leadingAnchor.constraint(equalTo: pageVC.view.leadingAnchor),
                    hostingController.view.trailingAnchor.constraint(equalTo: pageVC.view.trailingAnchor),
                    hostingController.view.bottomAnchor.constraint(equalTo: pageVC.view.bottomAnchor)
                ])
                hostingController.didMove(toParent: pageVC)
                return pageVC
            }
        }

        func viewController(for index: Int) -> UIViewController {
            guard index >= 0 && index < viewControllers.count else {
                return PageViewController(index: -1)
            }
            return viewControllers[index]
        }

        func index(of viewController: UIViewController) -> Int? {
            if let pageVC = viewController as? PageViewController {
                return pageVC.pageIndex
            }
            return nil
        }
        
        // MARK: - UIPageViewControllerDataSource
        
        func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let index = index(of: viewController), index > 0 else { return nil }
            return self.viewController(for: index - 1)
        }
        
        func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
            guard let index = index(of: viewController), index < parent.pages - 1 else { return nil }
            return self.viewController(for: index + 1)
        }
        
        // MARK: - UIPageViewControllerDelegate
        
        func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            guard completed,
                  let currentViewController = pageViewController.viewControllers?.first,
                  let currentIndex = index(of: currentViewController) else { return }
            
            // 更新绑定的 currentPage
            DispatchQueue.main.async {
                self.parent.currentPage = currentIndex
            }
        }
    }
}

// MARK: - Preview

struct PageCurlView_Previews: PreviewProvider {
    @State static var currentPage = 0
    
    static var previews: some View {
        PageCurlView(pages: 3, currentPage: $currentPage) { pageIndex in
            ZStack {
                Color.white
                VStack {
                    Text("页面 \(pageIndex + 1)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("这是第 \(pageIndex + 1) 页的内容")
                        .font(.body)
                        .padding()
                }
            }
        }
        .previewDisplayName("书页翻动预览")
    }
}
