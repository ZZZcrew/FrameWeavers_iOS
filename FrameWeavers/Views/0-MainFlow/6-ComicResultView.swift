import SwiftUI
import UIKit

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
        .ignoresSafeArea()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(true) // 隐藏系统导航栏
        // MARK: - 沉浸式体验
        // 1. 隐藏系统覆盖层（如Home Indicator）
        .persistentSystemOverlays(.hidden)
        .onAppear {
            // 初始隐藏菜单栏
            viewModel.isNavigationVisible = false
            // 强制横屏
            forceLandscapeOrientation()
        }
        .onDisappear {
            // 恢复默认方向设置
            restoreDefaultOrientation()
        }
    }
    
    // MARK: - Private Methods
    /// 强制横屏
    private func forceLandscapeOrientation() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
        }
        
        // 设置状态栏方向
        UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
    }
    
    /// 恢复默认方向
    private func restoreDefaultOrientation() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .all))
        }
        
        // 恢复状态栏方向
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
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

// MARK: - Adaptive Properties
private extension ComicResultView {
    /// 是否为紧凑尺寸设备
    var isCompact: Bool {
        horizontalSizeClass == .compact
    }
}

// MARK: - Private Methods
extension ComicResultView {

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
