import SwiftUI

/// 连环画结果视图 - 遵循MVVM架构，职责仅为组合UI与横屏控制
struct ComicResultView: View {    
    // MARK: - Properties
    let comicResult: ComicResult
    @StateObject private var viewModel: ComicResultViewModel

    init(comicResult: ComicResult) {
        self.comicResult = comicResult
        self._viewModel = StateObject(wrappedValue: ComicResultViewModel(comicResult: comicResult))
    }

    var body: some View {
        ZStack {
            ComicPageController(
                comicResult: comicResult,
                viewModel: viewModel
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // 阅读菜单栏 - 覆盖在内容之上
            ComicReaderMenuBar(
                isVisible: $viewModel.isNavigationVisible,
                onShareTapped: { viewModel.shareTapped() },
                onRecordTapped: { viewModel.recordTapped() }
            )
        }
        .ignoresSafeArea()
        .navigationBarHidden(true) // 隐藏系统导航栏
        .forceLandscape()
    }
    
}