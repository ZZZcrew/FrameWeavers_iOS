import SwiftUI

/// 连环画结果视图 - 遵循MVVM架构，只负责UI展示，强制横屏显示
struct ComicResultView: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    // MARK: - Properties
    let comicResult: ComicResult
    @StateObject private var viewModel: ComicResultViewModel

    init(comicResult: ComicResult) {
        self.comicResult = comicResult
        self._viewModel = StateObject(wrappedValue: ComicResultViewModel(comicResult: comicResult))
    }

    var body: some View {
        ZStack {
            // 强制横屏布局
            landscapeLayout
            
            // 阅读菜单栏 - 覆盖在内容之上
            ComicReaderMenuBar(
                isVisible: $viewModel.isNavigationVisible,
                onShareTapped: { viewModel.shareTapped() },
                onRecordTapped: { viewModel.recordTapped() }
            )
        }
        .ignoresSafeArea()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(true) // 隐藏系统导航栏
        .forceLandscape()
        .onAppear { viewModel.isNavigationVisible = false }
    }
    
}

// MARK: - Layout Components
private extension ComicResultView {
    /// 横屏布局 - 优化的翻页体验
    var landscapeLayout: some View {
        VStack(spacing: 0) {
            // 3D翻页内容区域
            ComicPageController(
                comicResult: comicResult,
                viewModel: viewModel
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background {
            Image("背景单色")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
    }
}
