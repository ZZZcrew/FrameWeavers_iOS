import XCTest
import SwiftData
import Combine
@testable import FrameWeavers

/// VideoUploadViewModel 单元测试
/// 测试重构后的VideoUploadViewModel的各项功能
final class VideoUploadViewModelTests: XCTestCase {
    
    // MARK: - 测试属性
    
    var viewModel: VideoUploadViewModel!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var cancellables: Set<AnyCancellable>!
    
    // MARK: - 测试生命周期
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // 创建内存中的测试数据库
        let schema = Schema([HistoryAlbum.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        modelContext = ModelContext(modelContainer)
        
        // 创建测试ViewModel
        viewModel = VideoUploadViewModel()
        viewModel.setHistoryService(modelContext: modelContext)
        
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        cancellables = nil
        viewModel = nil
        modelContext = nil
        modelContainer = nil
        try super.tearDownWithError()
    }
    
    // MARK: - 初始化测试
    
    /// 测试ViewModel初始状态
    func testInitialState() {
        XCTAssertEqual(viewModel.uploadStatus, .pending, "初始状态应该是pending")
        XCTAssertEqual(viewModel.uploadProgress, 0, "初始进度应该是0")
        XCTAssertNil(viewModel.errorMessage, "初始错误信息应该为nil")
        XCTAssertNil(viewModel.comicResult, "初始连环画结果应该为nil")
        XCTAssertTrue(viewModel.baseFrames.isEmpty, "初始基础帧应该为空")
        XCTAssertTrue(viewModel.keyFrames.isEmpty, "初始关键帧应该为空")
        XCTAssertFalse(viewModel.shouldNavigateToStyleSelection, "初始导航状态应该为false")
        XCTAssertEqual(viewModel.selectedStyle, "", "初始选择的风格应该为空")
    }
    
    // MARK: - 视频选择测试
    
    /// 测试视频选择功能
    func testVideoSelection() {
        // Given
        let testURL = URL(fileURLWithPath: "/test/video.mp4")
        
        // When
        viewModel.selectVideo(testURL)
        
        // Then
        XCTAssertEqual(viewModel.selectedVideo, testURL, "选择的视频应该匹配")
        XCTAssertEqual(viewModel.selectedVideos.count, 1, "应该有一个选择的视频")
        XCTAssertTrue(viewModel.shouldNavigateToStyleSelection, "应该触发导航到风格选择")
    }
    
    /// 测试多个视频选择
    func testMultipleVideoSelection() {
        // Given
        let testURLs = [
            URL(fileURLWithPath: "/test/video1.mp4"),
            URL(fileURLWithPath: "/test/video2.mp4")
        ]
        
        // When
        viewModel.selectVideos(testURLs)
        
        // Then
        XCTAssertEqual(viewModel.selectedVideos.count, 2, "应该有两个选择的视频")
        XCTAssertEqual(viewModel.selectedVideo, testURLs.first, "第一个视频应该是主选择")
        XCTAssertTrue(viewModel.shouldNavigateToStyleSelection, "应该触发导航到风格选择")
    }
    
    /// 测试添加视频
    func testAddVideo() {
        // Given
        let firstURL = URL(fileURLWithPath: "/test/video1.mp4")
        let secondURL = URL(fileURLWithPath: "/test/video2.mp4")
        
        // When
        viewModel.selectVideo(firstURL)
        viewModel.addVideo(secondURL)
        
        // Then
        XCTAssertEqual(viewModel.selectedVideos.count, 2, "应该有两个视频")
        XCTAssertTrue(viewModel.selectedVideos.contains(firstURL), "应该包含第一个视频")
        XCTAssertTrue(viewModel.selectedVideos.contains(secondURL), "应该包含第二个视频")
    }
    
    /// 测试移除视频
    func testRemoveVideo() {
        // Given
        let testURLs = [
            URL(fileURLWithPath: "/test/video1.mp4"),
            URL(fileURLWithPath: "/test/video2.mp4")
        ]
        viewModel.selectVideos(testURLs)
        
        // When
        viewModel.removeVideo(at: 0)
        
        // Then
        XCTAssertEqual(viewModel.selectedVideos.count, 1, "应该剩余一个视频")
        XCTAssertEqual(viewModel.selectedVideos.first, testURLs[1], "应该剩余第二个视频")
    }
    
    // MARK: - 风格选择测试
    
    /// 测试风格选择
    func testStyleSelection() {
        // Given
        let testStyle = "温馨童话"
        
        // When
        viewModel.selectStyle(testStyle)
        
        // Then
        XCTAssertEqual(viewModel.selectedStyle, testStyle, "选择的风格应该匹配")
    }
    
    // MARK: - 生成流程测试
    
    /// 测试开始生成 - 成功场景
    func testStartGenerationSuccess() {
        // Given
        let testURL = URL(fileURLWithPath: "/test/video.mp4")
        let testStyle = "温馨童话"

        viewModel.selectVideo(testURL)
        viewModel.selectStyle(testStyle)

        // When
        let result = viewModel.startGeneration()

        // Then
        XCTAssertTrue(result, "生成应该成功开始")
        // 注意：由于startGeneration会触发实际的上传流程，我们只验证方法返回值
        // 实际的状态变化需要在集成测试中验证
    }
    
    /// 测试开始生成 - 没有选择风格
    func testStartGenerationNoStyle() {
        // Given
        let testURL = URL(fileURLWithPath: "/test/video.mp4")
        viewModel.selectVideo(testURL)
        // 不选择风格
        
        // When
        let result = viewModel.startGeneration()
        
        // Then
        XCTAssertFalse(result, "生成应该失败")
    }
    
    /// 测试开始生成 - 没有选择视频
    func testStartGenerationNoVideo() {
        // Given
        let testStyle = "温馨童话"
        viewModel.selectStyle(testStyle)
        // 不选择视频
        
        // When
        let result = viewModel.startGeneration()
        
        // Then
        XCTAssertFalse(result, "生成应该失败")
        XCTAssertNotNil(viewModel.errorMessage, "应该有错误信息")
    }
    
    /// 测试带风格的生成方法
    func testStartGenerationWithStyle() {
        // Given
        let testURL = URL(fileURLWithPath: "/test/video.mp4")
        let testStyle = "温馨童话"
        
        viewModel.selectVideo(testURL)
        
        // When
        let result = viewModel.startGeneration(with: testStyle)
        
        // Then
        XCTAssertTrue(result, "生成应该成功开始")
        XCTAssertEqual(viewModel.selectedStyle, testStyle, "风格应该被设置")
    }
    
    // MARK: - 重置功能测试
    
    /// 测试重置功能
    func testReset() {
        // Given - 设置一些状态
        let testURL = URL(fileURLWithPath: "/test/video.mp4")
        viewModel.selectVideo(testURL)
        viewModel.selectStyle("温馨童话")
        viewModel.uploadStatus = .uploading
        viewModel.uploadProgress = 0.5
        viewModel.errorMessage = "测试错误"
        
        // When
        viewModel.reset()
        
        // Then
        XCTAssertEqual(viewModel.uploadStatus, .pending, "状态应该重置")
        XCTAssertEqual(viewModel.uploadProgress, 0, "进度应该重置")
        XCTAssertNil(viewModel.errorMessage, "错误信息应该清除")
        XCTAssertNil(viewModel.comicResult, "连环画结果应该清除")
        XCTAssertTrue(viewModel.selectedVideos.isEmpty, "选择的视频应该清除")
        XCTAssertFalse(viewModel.shouldNavigateToStyleSelection, "导航状态应该重置")
        XCTAssertEqual(viewModel.selectedStyle, "", "选择的风格应该重置")
    }
    
    /// 测试重置导航状态
    func testResetNavigationState() {
        // Given
        viewModel.shouldNavigateToStyleSelection = true
        viewModel.selectedStyle = "温馨童话"
        
        // When
        viewModel.resetNavigationState()
        
        // Then
        XCTAssertFalse(viewModel.shouldNavigateToStyleSelection, "导航状态应该重置")
        XCTAssertEqual(viewModel.selectedStyle, "", "选择的风格应该重置")
    }
    
    // MARK: - 历史记录功能测试
    
    /// 测试获取历史记录摘要
    func testGetHistorySummary() {
        // When
        let summary = viewModel.getHistorySummary()
        
        // Then
        XCTAssertNotNil(summary, "应该能获取历史记录摘要")
        XCTAssertEqual(summary?.totalCount, 0, "初始应该没有历史记录")
        XCTAssertFalse(summary?.hasHistory ?? true, "初始应该没有历史记录")
    }
    
    /// 测试检查连环画是否已存在
    func testIsComicAlreadyExists() {
        // Given
        let testComicId = "test-comic-id"
        
        // When
        let exists = viewModel.isComicAlreadyExists(testComicId)
        
        // Then
        XCTAssertFalse(exists, "不存在的连环画应该返回false")
    }
    
    // MARK: - 状态观察测试
    
    /// 测试状态变化的发布
    func testStatusChangePublishing() {
        // Given
        let expectation = XCTestExpectation(description: "状态变化")
        var receivedStatus: UploadStatus?
        
        viewModel.$uploadStatus
            .dropFirst() // 跳过初始值
            .sink { status in
                receivedStatus = status
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        viewModel.uploadStatus = .uploading
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedStatus, .uploading, "应该接收到状态变化")
    }
    
    /// 测试进度变化的发布
    func testProgressChangePublishing() {
        // Given
        let expectation = XCTestExpectation(description: "进度变化")
        var receivedProgress: Double?
        
        viewModel.$uploadProgress
            .dropFirst() // 跳过初始值
            .sink { progress in
                receivedProgress = progress
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        viewModel.uploadProgress = 0.5
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedProgress, 0.5, "应该接收到进度变化")
    }
    
    // MARK: - 边界条件测试
    
    /// 测试空视频列表的处理
    func testEmptyVideoList() {
        // When
        viewModel.selectVideos([])
        
        // Then
        XCTAssertTrue(viewModel.selectedVideos.isEmpty, "空列表应该保持为空")
        XCTAssertNil(viewModel.selectedVideo, "主选择应该为nil")
        XCTAssertFalse(viewModel.shouldNavigateToStyleSelection, "不应该触发导航")
    }
    
    /// 测试移除不存在的索引
    func testRemoveVideoInvalidIndex() {
        // Given
        let testURL = URL(fileURLWithPath: "/test/video.mp4")
        viewModel.selectVideo(testURL)
        
        // When & Then - 这应该不会崩溃
        viewModel.removeVideo(at: 10) // 无效索引
        
        // 验证原有视频仍然存在
        XCTAssertEqual(viewModel.selectedVideos.count, 1, "原有视频应该仍然存在")
    }
}
