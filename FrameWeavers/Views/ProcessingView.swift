import SwiftUI

/// 处理视图 - 遵循MVVM架构，只负责UI展示
struct ProcessingView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: VideoUploadViewModel
    @StateObject private var galleryViewModel = ProcessingGalleryViewModel()
    @State private var frames: [String: CGRect] = [:]
    @Namespace private var galleryNamespace
    
    // 定时器
    let scrollTimer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    let jumpTimer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // 背景色
            Color(red: 0.91, green: 0.88, blue: 0.83).ignoresSafeArea()

            VStack(spacing: 40) {
                // 始终显示胶片画廊视图
                filmGalleryView
            }
            .padding(.vertical, 50)

            // 飞行图片覆盖层
            if let info = galleryViewModel.flyingImageInfo {
                let baseFrame = galleryViewModel.getBaseFrame(for: info.id)
                if let baseFrame = baseFrame, let url = baseFrame.thumbnailURL {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(ProgressView().scaleEffect(0.5))
                    }
                    .frame(width: info.sourceFrame.width, height: info.sourceFrame.height)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .matchedGeometryEffect(id: info.id, in: galleryNamespace)
                    .position(x: info.sourceFrame.midX, y: info.sourceFrame.midY)
                    .transition(.identity)
                } else if baseFrame == nil {
                    // 只有在没有基础帧数据时才显示本地图片
                    Image(info.id)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: info.sourceFrame.width, height: info.sourceFrame.height)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .matchedGeometryEffect(id: info.id, in: galleryNamespace)
                        .position(x: info.sourceFrame.midX, y: info.sourceFrame.midY)
                        .transition(.identity)
                } else {
                    // 有基础帧数据但URL无效时显示错误状态
                    Rectangle()
                        .fill(Color.orange.opacity(0.3))
                        .frame(width: info.sourceFrame.width, height: info.sourceFrame.height)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .matchedGeometryEffect(id: info.id, in: galleryNamespace)
                        .position(x: info.sourceFrame.midX, y: info.sourceFrame.midY)
                        .transition(.identity)
                }
            }
        }
        .onPreferenceChange(FramePreferenceKey.self) { value in
            self.frames.merge(value, uniquingKeysWith: { $1 })
        }
        .onReceive(scrollTimer) { _ in
            handleScrollTimer()
        }
        .onReceive(jumpTimer) { _ in
            handleJumpTimer()
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
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color(hex: "#2F2617"))
                }
            }
        }
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

    /// 处理跳跃动画定时器事件
    private func handleJumpTimer() {
        // 只有在有基础帧数据时才播放跳跃动画
        if viewModel.uploadStatus != .completed && viewModel.uploadStatus != .failed && !viewModel.baseFrames.isEmpty {
            withAnimation(.easeInOut(duration: 1.2)) {
                galleryViewModel.triggerJumpAnimation(from: frames)
            }
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
        // 状态变化的处理逻辑已经移到ViewModel中
        // 这里只保留必要的UI响应
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
