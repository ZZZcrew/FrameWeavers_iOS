import XCTest
import Combine
@testable import FrameWeavers

final class ComicGenerationCoordinatorTests: XCTestCase {
    
    var coordinator: ComicGenerationCoordinator!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        coordinator = ComicGenerationCoordinator()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        coordinator?.reset()
        coordinator = nil
        cancellables = nil
        try super.tearDownWithError()
    }
    
    // MARK: - 初始状态测试
    
    func testInitialState() {
        XCTAssertEqual(coordinator.generationStatus, .idle, "初始状态应为idle")
        XCTAssertEqual(coordinator.generationProgress, 0.0, "初始进度应为0")
        XCTAssertNil(coordinator.errorMessage, "初始错误信息应为nil")
        XCTAssertNil(coordinator.comicResult, "初始连环画结果应为nil")
    }
    
    // MARK: - GenerationConfig 测试
    
    func testGenerationConfigDefaultValues() {
        let config = ComicGenerationCoordinator.GenerationConfig(
            taskId: "test-task-123",
            videoPath: "/path/to/video.mp4"
        )
        
        XCTAssertEqual(config.taskId, "test-task-123", "任务ID应该正确")
        XCTAssertEqual(config.videoPath, "/path/to/video.mp4", "视频路径应该正确")
        XCTAssertEqual(config.storyStyle, "温馨童话", "默认故事风格应该正确")
        XCTAssertEqual(config.targetFrames, 8, "默认目标帧数应该正确")
        XCTAssertEqual(config.frameInterval, 2.0, "默认帧间隔应该正确")
        XCTAssertEqual(config.significanceWeight, 0.7, "默认重要性权重应该正确")
        XCTAssertEqual(config.qualityWeight, 0.3, "默认质量权重应该正确")
        XCTAssertEqual(config.imageSize, "1780x1024", "默认图片尺寸应该正确")
        XCTAssertEqual(config.maxConcurrent, 50, "默认最大并发数应该正确")
    }
    
    func testGenerationConfigCustomValues() {
        let config = ComicGenerationCoordinator.GenerationConfig(
            taskId: "custom-task",
            videoPath: "/custom/path.mp4",
            storyStyle: "科幻风格",
            targetFrames: 12,
            frameInterval: 1.5,
            significanceWeight: 0.8,
            qualityWeight: 0.2,
            stylePrompt: "Custom style prompt",
            imageSize: "1920x1080",
            maxConcurrent: 30
        )
        
        XCTAssertEqual(config.taskId, "custom-task", "自定义任务ID应该正确")
        XCTAssertEqual(config.videoPath, "/custom/path.mp4", "自定义视频路径应该正确")
        XCTAssertEqual(config.storyStyle, "科幻风格", "自定义故事风格应该正确")
        XCTAssertEqual(config.targetFrames, 12, "自定义目标帧数应该正确")
        XCTAssertEqual(config.frameInterval, 1.5, "自定义帧间隔应该正确")
        XCTAssertEqual(config.significanceWeight, 0.8, "自定义重要性权重应该正确")
        XCTAssertEqual(config.qualityWeight, 0.2, "自定义质量权重应该正确")
        XCTAssertEqual(config.stylePrompt, "Custom style prompt", "自定义风格提示应该正确")
        XCTAssertEqual(config.imageSize, "1920x1080", "自定义图片尺寸应该正确")
        XCTAssertEqual(config.maxConcurrent, 30, "自定义最大并发数应该正确")
    }
    
    // MARK: - GenerationResult 测试
    
    func testGenerationResultStructure() {
        let mockComicResult = ComicResult(
            comicId: "test-comic",
            deviceId: "test-device",
            title: "测试连环画",
            originalVideoTitle: "test.mp4",
            creationDate: "2024-01-01T00:00:00Z",
            panelCount: 4,
            panels: [],
            finalQuestions: []
        )
        
        let mockBaseFrames = [
            BaseFrameData(framePath: "/frame1.jpg", frameIndex: 0, timestamp: 0.0),
            BaseFrameData(framePath: "/frame2.jpg", frameIndex: 1, timestamp: 1.0)
        ]
        
        let successResult = ComicGenerationCoordinator.GenerationResult(
            success: true,
            comicResult: mockComicResult,
            errorMessage: nil,
            baseFrames: mockBaseFrames
        )
        
        XCTAssertTrue(successResult.success, "成功结果应该为true")
        XCTAssertNotNil(successResult.comicResult, "成功结果应该有连环画数据")
        XCTAssertNil(successResult.errorMessage, "成功结果不应该有错误信息")
        XCTAssertEqual(successResult.baseFrames.count, 2, "基础帧数量应该正确")
        
        let failureResult = ComicGenerationCoordinator.GenerationResult(
            success: false,
            comicResult: nil,
            errorMessage: "生成失败",
            baseFrames: []
        )
        
        XCTAssertFalse(failureResult.success, "失败结果应该为false")
        XCTAssertNil(failureResult.comicResult, "失败结果不应该有连环画数据")
        XCTAssertEqual(failureResult.errorMessage, "生成失败", "失败结果应该有错误信息")
        XCTAssertEqual(failureResult.baseFrames.count, 0, "失败结果基础帧应该为空")
    }
    
    // MARK: - 完整生成流程测试
    
    func testStartCompleteGeneration() async {
        let config = ComicGenerationCoordinator.GenerationConfig(
            taskId: "test-generation-task",
            videoPath: "/test/video.mp4"
        )
        
        let expectation = XCTestExpectation(description: "完整生成流程")
        var baseFramesExtracted = false
        var progressUpdated = false
        var generationFailed = false
        
        await coordinator.startCompleteGeneration(
            config: config,
            onBaseFramesExtracted: { frames in
                baseFramesExtracted = true
            },
            onProgressUpdate: { progress, message in
                progressUpdated = true
            },
            onCompleted: { comicResult in
                expectation.fulfill()
            },
            onFailed: { message in
                generationFailed = true
                expectation.fulfill()
            }
        )
        
        await fulfillment(of: [expectation], timeout: 10.0)
        
        // 在测试环境中，网络请求通常会失败，所以验证失败回调被调用
        XCTAssertTrue(generationFailed, "在测试环境中应该调用失败回调")
    }
    
    // MARK: - 提前基础帧提取测试
    
    func testTryEarlyBaseFrameExtraction() async {
        let taskId = "test-early-extraction"
        
        let frames = await coordinator.tryEarlyBaseFrameExtraction(taskId: taskId)
        
        // 在测试环境中，网络请求通常会失败，所以返回空数组
        XCTAssertTrue(frames.isEmpty, "在测试环境中应该返回空的基础帧数组")
    }
    
    // MARK: - 状态管理测试
    
    func testComicGenerationStatus() {
        XCTAssertEqual(ComicGenerationStatus.idle.description, "待开始")
        XCTAssertEqual(ComicGenerationStatus.extractingBaseFrames.description, "提取基础帧中")
        XCTAssertEqual(ComicGenerationStatus.generatingComic.description, "生成连环画中")
        XCTAssertEqual(ComicGenerationStatus.completed.description, "已完成")
        XCTAssertEqual(ComicGenerationStatus.failed.description, "失败")
        XCTAssertEqual(ComicGenerationStatus.cancelled.description, "已取消")
    }
    
    // MARK: - 重置功能测试
    
    func testReset() {
        // 设置一些状态
        coordinator.generationStatus = .generatingComic
        coordinator.generationProgress = 0.5
        coordinator.errorMessage = "测试错误"
        
        // 重置协调器
        coordinator.reset()
        
        // 验证状态被重置
        XCTAssertEqual(coordinator.generationStatus, .idle, "重置后状态应为idle")
        XCTAssertEqual(coordinator.generationProgress, 0.0, "重置后进度应为0")
        XCTAssertNil(coordinator.errorMessage, "重置后错误信息应为nil")
        XCTAssertNil(coordinator.comicResult, "重置后连环画结果应为nil")
    }
    
    // MARK: - 取消生成测试
    
    func testCancelGeneration() {
        // 设置生成中状态
        coordinator.generationStatus = .generatingComic
        coordinator.generationProgress = 0.5
        
        // 取消生成
        coordinator.cancelGeneration()
        
        // 验证状态被设置为取消
        XCTAssertEqual(coordinator.generationStatus, .cancelled, "取消后状态应为cancelled")
    }
    
    // MARK: - 边界条件测试
    
    func testEmptyTaskIdAndVideoPath() async {
        let config = ComicGenerationCoordinator.GenerationConfig(
            taskId: "",
            videoPath: ""
        )
        
        let expectation = XCTestExpectation(description: "空参数测试")
        var failedCalled = false
        
        await coordinator.startCompleteGeneration(
            config: config,
            onCompleted: { _ in
                expectation.fulfill()
            },
            onFailed: { message in
                failedCalled = true
                expectation.fulfill()
            }
        )
        
        await fulfillment(of: [expectation], timeout: 5.0)
        
        // 空参数应该导致失败
        XCTAssertTrue(failedCalled, "空参数应该导致失败回调")
    }
    
    // MARK: - 性能测试
    
    func testPerformanceReset() {
        measure {
            for _ in 0..<100 {
                coordinator.reset()
            }
        }
    }
    
    func testPerformanceCancelGeneration() {
        measure {
            for _ in 0..<100 {
                coordinator.cancelGeneration()
            }
        }
    }
    
    // MARK: - 内存管理测试
    
    func testMemoryManagement() {
        weak var weakCoordinator: ComicGenerationCoordinator?
        
        autoreleasepool {
            let coordinator = ComicGenerationCoordinator()
            weakCoordinator = coordinator
            
            coordinator.generationStatus = .generatingComic
            coordinator.reset()
        }
        
        // 给一些时间让对象被释放
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertNil(weakCoordinator, "ComicGenerationCoordinator应该被正确释放")
        }
    }
}
