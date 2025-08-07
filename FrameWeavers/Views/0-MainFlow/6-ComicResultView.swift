import SwiftUI
import UIKit

/// 连环画结果视图 - 遵循MVVM架构，只负责UI展示
struct ComicResultView: View {
    @Environment(\.dismiss) private var dismiss
    let comicResult: ComicResult
    @StateObject private var viewModel: ComicResultViewModel

    init(comicResult: ComicResult) {
        self.comicResult = comicResult
        self._viewModel = StateObject(wrappedValue: ComicResultViewModel(comicResult: comicResult))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    // 3D翻页内容区域
                    ComicPageController(
                        comicResult: comicResult,
                        viewModel: viewModel,
                        geometry: geometry
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .background {
                    Image("背景单色")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                }

                // 阅读菜单栏 - 覆盖在内容之上
                ComicReaderMenuBar(
                    isVisible: $viewModel.isNavigationVisible,
                    geometry: geometry,
                    onShareTapped: {
                        // 分享功能占位符 - 显示提示
                        showSharePlaceholder()
                    },
                    onRecordTapped: {
                        // 记录功能占位符 - 显示提示
                        showRecordPlaceholder()
                    }
                )
            }
        }
        .ignoresSafeArea()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(true) // 隐藏系统导航栏
        // MARK: - 沉浸式体验
        // 1. 隐藏系统覆盖层（如Home Indicator）
        .persistentSystemOverlays(.hidden)
        .onAppear {
            // 强制横屏显示
            AppDelegate.orientationLock = .landscape
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
            }

            // 初始隐藏菜单栏
            viewModel.isNavigationVisible = false
        }
    }

    // MARK: - Private Methods

    /// 分享功能占位符
    private func showSharePlaceholder() {
        print("分享功能占位符：将来可以实现分享连环画到社交媒体等功能")
        // 这里可以添加一个简单的提示或者未来的分享功能
        // 例如：显示一个Alert或者Toast提示
    }

    /// 记录功能占位符
    private func showRecordPlaceholder() {
        print("记录功能占位符：将来可以实现阅读记录、书签等功能")
        // 这里可以添加记录相关的功能
        // 例如：保存阅读进度、添加书签等
    }
}
