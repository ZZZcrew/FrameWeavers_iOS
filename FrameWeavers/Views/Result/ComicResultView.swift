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
        }
        .ignoresSafeArea()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // 强制横屏显示
            AppDelegate.orientationLock = .landscape
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
            UINavigationController.attemptRotationToDeviceOrientation()
        }
    }
}
