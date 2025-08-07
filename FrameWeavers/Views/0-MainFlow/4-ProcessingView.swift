import SwiftUI

/// 处理视图 - 遵循MVVM架构，只负责UI展示，采用现代响应式设计
struct ProcessingView: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    // MARK: - Properties
    @ObservedObject var viewModel: VideoUploadViewModel
    @StateObject private var galleryViewModel = ProcessingGalleryViewModel()
    @Namespace private var galleryNamespace
    @State private var navigateToResults = false

    var body: some View {
        ZStack {
            // 背景图片
            backgroundImage

            // 使用Size Classes进行响应式布局
            if isLandscape {
                landscapeLayout
            } else {
                portraitLayout
            }
        }
        .onAppear {
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
    }
}

// MARK: - 响应式布局扩展
extension ProcessingView {

    /// 背景图片
    private var backgroundImage: some View {
        Image("背景单色")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
    }

    /// 竖屏布局 - 使用现代响应式设计
    private var portraitLayout: some View {
        VStack(spacing: portraitSpacing) {
            Spacer(minLength: portraitTopSpacing)

            // 图片堆叠区域
            PhotoStackView(
                mainImageName: galleryViewModel.mainImageName,
                stackedImages: galleryViewModel.stackedImages,
                namespace: galleryNamespace,
                baseFrames: galleryViewModel.baseFrameDataMap
            )
            .frame(maxHeight: portraitPhotoStackHeight)

            Spacer(minLength: portraitMiddleSpacing)

            // 胶片画廊区域
            FilmstripView(
                baseFrames: galleryViewModel.baseFrames,
                isExampleMode: galleryViewModel.isExampleMode,
                config: galleryViewModel.filmstripConfig,
                comicResult: (viewModel as? MockVideoUploadViewModel)?.targetComicResult,
                customScrollSpeed: 50.0,
                onImageTapped: { imageId in
                    galleryViewModel.selectImage(imageId)
                }
            )
            .frame(maxHeight: portraitFilmstripHeight)
            
            Spacer(minLength: portraitMiddleSpacing)

            // 进度显示区域
            ProcessingLoadingView(
                progress: viewModel.uploadProgress,
                status: viewModel.uploadStatus
            )

            Spacer(minLength: portraitBottomSpacing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// 横屏布局 - 符合规范的简化水平布局
    private var landscapeLayout: some View {
        HStack(spacing: landscapeSpacing) {
            // 左侧：主要内容区域
            VStack(spacing: landscapeContentSpacing) {
                // 图片堆叠区域 - 横屏时稍大
                PhotoStackView(
                    mainImageName: galleryViewModel.mainImageName,
                    stackedImages: galleryViewModel.stackedImages,
                    namespace: galleryNamespace,
                    baseFrames: galleryViewModel.baseFrameDataMap
                )
                .frame(maxHeight: landscapePhotoStackHeight)

                // 胶片画廊区域 - 横屏时保持紧凑
                FilmstripView(
                    baseFrames: galleryViewModel.baseFrames,
                    isExampleMode: galleryViewModel.isExampleMode,
                    config: galleryViewModel.filmstripConfig,
                    comicResult: (viewModel as? MockVideoUploadViewModel)?.targetComicResult,
                    customScrollSpeed: 50.0,
                    onImageTapped: { imageId in
                        galleryViewModel.selectImage(imageId)
                    }
                )
                .frame(maxHeight: landscapeFilmstripHeight)
            }
            .frame(maxWidth: .infinity)

            // 右侧：进度显示区域
            VStack(spacing: 15) {
                Spacer()
                ProcessingLoadingView(
                    progress: viewModel.uploadProgress,
                    status: viewModel.uploadStatus
                )
                Spacer()
            }
            .frame(width: landscapeProgressAreaWidth)
        }
        .padding(.horizontal, landscapePadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 响应式属性
extension ProcessingView {

    /// 是否为紧凑尺寸
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    /// 是否为横屏模式 - 更通用的检测逻辑
    private var isLandscape: Bool {
        // 方法1：主要基于verticalSizeClass检测
        verticalSizeClass == .compact

        // 备注：这样可以覆盖所有设备的横屏情况：
        // - iPhone标准尺寸横屏：horizontalSizeClass=.compact, verticalSizeClass=.compact
        // - iPhone Plus/Max横屏：horizontalSizeClass=.regular, verticalSizeClass=.compact
        // - iPad横屏：根据分屏情况可能不同，但verticalSizeClass=.compact是可靠指标
    }

    // MARK: - 竖屏属性
    private var portraitSpacing: CGFloat { isCompact ? 16 : 24 }
    private var portraitTopSpacing: CGFloat { isCompact ? 20 : 40 }
    private var portraitMiddleSpacing: CGFloat { isCompact ? 30 : 50 }
    private var portraitBottomSpacing: CGFloat { isCompact ? 20 : 40 }
    private var portraitPadding: CGFloat { isCompact ? 20 : 40 }
    private var portraitGallerySpacing: CGFloat { isCompact ? 20 : 30 }
    private var portraitPhotoStackHeight: CGFloat { isCompact ? 250 : 300 }
    private var portraitFilmstripHeight: CGFloat { isCompact ? 100 : 120 }

    // MARK: - 横屏属性 (符合规范：充分利用水平空间，适配不同设备)
    private var landscapeSpacing: CGFloat {
        // 根据水平尺寸类调整间距
        horizontalSizeClass == .regular ? 50 : 40
    }

    private var landscapePadding: CGFloat {
        horizontalSizeClass == .regular ? 40 : 30
    }

    private var landscapeContentSpacing: CGFloat {
        horizontalSizeClass == .regular ? 30 : 25
    }

    private var landscapePhotoStackHeight: CGFloat {
        // 大屏设备横屏时可以更大
        horizontalSizeClass == .regular ? 250 : 220
    }

    private var landscapeFilmstripHeight: CGFloat {
        horizontalSizeClass == .regular ? 100 : 90
    }

    private var landscapeProgressAreaWidth: CGFloat {
        horizontalSizeClass == .regular ? 320 : 280
    }
}

// MARK: - 事件处理扩展
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