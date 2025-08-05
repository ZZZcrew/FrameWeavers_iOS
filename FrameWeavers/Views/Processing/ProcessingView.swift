import SwiftUI

/// 处理视图 - 遵循MVVM架构，只负责UI展示
struct ProcessingView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: VideoUploadViewModel
    @StateObject private var galleryViewModel = ProcessingGalleryViewModel()
    @Namespace private var galleryNamespace
    @State private var navigateToResults = false // 添加导航状态

    var body: some View {
        ZStack {
            // 背景图片
            Image("背景单色")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            GeometryReader { geometry in
                // 强制竖屏布局
                portraitLayout(geometry)
            }
        }

        .onAppear {
            // 强制竖屏显示
            AppDelegate.orientationLock = .portrait
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            }

            handleViewAppear()
            // 检查是否为示例模式
            if let mockViewModel = viewModel as? MockVideoUploadViewModel, mockViewModel.isExampleMode {
                print("🎭 检测到示例模式，设置 galleryViewModel 为示例模式")
                galleryViewModel.setExampleMode(true, comicResult: mockViewModel.targetComicResult)
            } else {
                // 立即检查是否已有基础帧数据
                print("🔍 ProcessingView onAppear: 检查现有基础帧数据，数量: \(viewModel.baseFrames.count)")
                if !viewModel.baseFrames.isEmpty {
                    print("🎯 发现现有基础帧数据，立即设置到 galleryViewModel")
                    galleryViewModel.setBaseFrames(viewModel.baseFrames)
                }
            }
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
        // .onDisappear {
        //     // 离开时恢复支持所有方向
        //     AppDelegate.orientationLock = .all
        // }
    }
}

// MARK: - 布局扩展
extension ProcessingView {

    /// 竖屏布局
    @ViewBuilder
    private func portraitLayout(_ geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // 顶部弹性空间
            Spacer()
                .frame(minHeight: 20)

            // 胶片画廊区域
            VStack(spacing: 30) {
                PhotoStackView(
                    mainImageName: galleryViewModel.mainImageName,
                    stackedImages: galleryViewModel.stackedImages,
                    namespace: galleryNamespace,
                    baseFrames: galleryViewModel.baseFrameDataMap
                )
                .frame(maxHeight: geometry.size.height * 0.35)

                FilmstripView(
                    baseFrames: galleryViewModel.baseFrames,
                    isExampleMode: galleryViewModel.isExampleMode,
                    config: galleryViewModel.filmstripConfig,
                    comicResult: (viewModel as? MockVideoUploadViewModel)?.targetComicResult,
                    customScrollSpeed: 50.0  // 设置较慢的滚动速度
                )
                .frame(maxHeight: geometry.size.height * 0.2)
            }

            // 中间弹性空间
            Spacer()
                .frame(height: 40)

            // 进度显示区域
            ProcessingLoadingView(
                progress: viewModel.uploadProgress,
                status: viewModel.uploadStatus
            )
            .padding(.horizontal, 20)

            // 底部弹性空间
            Spacer()
                .frame(minHeight: 40)
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Subviews

extension ProcessingView {
    // MARK: - 事件处理方法

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