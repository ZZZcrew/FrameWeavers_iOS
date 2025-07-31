import SwiftUI

/// 处理视图 - 遵循MVVM架构，只负责UI展示
struct ProcessingView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: VideoUploadViewModel
    @StateObject private var galleryViewModel = ProcessingGalleryViewModel()
    @State private var frames: [String: CGRect] = [:]
    @Namespace private var galleryNamespace
    @State private var navigateToResults = false // 添加导航状态
    
    // 定时器
    let scrollTimer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // 背景色
            Color(red: 0.91, green: 0.88, blue: 0.83).ignoresSafeArea()

            VStack(spacing: 40) {
                // 始终显示胶片画廊视图
                filmGalleryView
            }
            .padding(.vertical, 50)

            // 飞行图片覆盖层 - 使用独立的飞跃动画组件
            FlyingImageController(
                galleryViewModel: galleryViewModel,
                namespace: galleryNamespace,
                frames: frames,
                isAnimationEnabled: viewModel.uploadStatus != .completed && viewModel.uploadStatus != .failed && !viewModel.baseFrames.isEmpty
            )
        }
        .onPreferenceChange(FramePreferenceKey.self) { value in
            self.frames.merge(value, uniquingKeysWith: { $1 })
        }
        .onReceive(scrollTimer) { _ in
            handleScrollTimer()
        }
        .onAppear {
            handleViewAppear()
        }
        .onChange(of: viewModel.uploadStatus) { _, newStatus in
            handleStatusChange(newStatus)
        }
        .onChange(of: viewModel.baseFrames) { _, newFrames in
            handleBaseFramesChange(newFrames)
        }
        // 添加导航逻辑
        .navigationDestination(isPresented: $navigateToResults) {
            if let comicResult = viewModel.comicResult {
                OpenResultsView(comicResult: comicResult)
            } else {
                // 错误处理视图
                Text("生成失败，请重试")
                    .foregroundColor(.red)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        // .navigationBarBackButtonHidden(false)
        // .toolbarBackground(Color.clear, for: .navigationBar)
    }
}

// MARK: - Subviews

extension ProcessingView {
    /// 胶片画廊视图
    private var filmGalleryView: some View {
        VStack(spacing: 40) {
            PhotoStackView(
                mainImageName: galleryViewModel.mainImageName,
                stackedImages: galleryViewModel.stackedImages,
                namespace: galleryNamespace,
                baseFrames: galleryViewModel.baseFrameDataMap,
                hideSourceImageId: galleryViewModel.hideSourceImageId
            )
                .anchorPreference(key: FramePreferenceKey.self, value: .bounds) { anchor in
                    return ["photoStackTarget": self.frames(from: anchor)]
                }

            FilmstripView(
                imageNames: galleryViewModel.imageNames,
                loopedImageNames: galleryViewModel.loopedImageNames,
                hideSourceImageId: galleryViewModel.hideSourceImageId,
                baseFrames: galleryViewModel.baseFrameDataMap,
                namespace: galleryNamespace,
                scrollOffset: galleryViewModel.scrollOffset
            )

            // 统一的进度条显示，在所有等待状态下都显示
            ProcessingLoadingView(progress: viewModel.uploadProgress, status: viewModel.uploadStatus)

            Spacer()
        }
    }

    
    /// Helper to convert anchor to global frame
    private func frames(from anchor: Anchor<CGRect>) -> CGRect {
        // 这里应该返回实际的全局frame，但由于我们在FilmstripView中已经处理了frame计算
        // 这个方法主要用于PhotoStackView的target frame
        return CGRect(x: UIScreen.main.bounds.midX - 150, y: 100, width: 300, height: 200)
    }

    // MARK: - 事件处理方法

    /// 处理滚动定时器事件
    private func handleScrollTimer() {
        // 在所有等待状态下都播放滚动动画
        if viewModel.uploadStatus != .completed && viewModel.uploadStatus != .failed {
            galleryViewModel.currentScrollIndex += 1
        }
    }



    /// 处理视图出现事件
    private func handleViewAppear() {
        if viewModel.uploadStatus == .pending {
            viewModel.uploadVideo()
        }
    }

    /// 处理状态变化
    /// - Parameter newStatus: 新的上传状态
    private func handleStatusChange(_ newStatus: UploadStatus) {
        // 当状态变为完成时，触发导航
        if newStatus == .completed {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.navigateToResults = true
            }
        }
    }

    /// 处理基础帧数据变化
    /// - Parameter newFrames: 新的基础帧数据
    private func handleBaseFramesChange(_ newFrames: [BaseFrameData]) {
        print("🔄 ProcessingView: baseFrames 发生变化, 数量: \(newFrames.count)")
        if !newFrames.isEmpty {
            print("🎯 设置基础帧到 galleryViewModel")
            galleryViewModel.setBaseFrames(newFrames)
        }
    }
}

// MARK: - Preview

struct ProcessingView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = VideoUploadViewModel()
        viewModel.uploadStatus = .processing
        viewModel.uploadProgress = 0.5
        return ProcessingView(viewModel: viewModel)
    }
}