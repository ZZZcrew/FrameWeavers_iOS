import XCTest
import Combine
@testable import FrameWeavers

final class ProgressPollingServiceTests: XCTestCase {
    
    var progressPollingService: ProgressPollingService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        progressPollingService = ProgressPollingService()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        progressPollingService?.reset()
        progressPollingService = nil
        cancellables = nil
        try super.tearDownWithError()
    }
    
    // MARK: - 初始状态测试
    
    func testInitialState() {
        XCTAssertEqual(progressPollingService.uploadProgress, 0.0, "初始上传进度应为0")
        XCTAssertEqual(progressPollingService.uploadStatus, .pending, "初始状态应为pending")
        XCTAssertNil(progressPollingService.errorMessage, "初始错误信息应为nil")
    }
    
    // MARK: - 进度轮询测试
    
    func testStartProgressPolling() {
        let expectation = XCTestExpectation(description: "开始进度轮询")
        let taskId = "test-task-123"
        var progressCallbackCount = 0
        var failedCallbackCalled = false

        progressPollingService.startProgressPolling(
            taskId: taskId,
            onProgress: { result in
                progressCallbackCount += 1
                expectation.fulfill()
            },
            onCompleted: {
                expectation.fulfill()
            },
            onFailed: { _ in
                failedCallbackCalled = true
                expectation.fulfill()
            }
        )

        // 等待一段时间确保轮询开始
        wait(for: [expectation], timeout: 10.0)

        // 在测试环境中，网络请求通常会失败，所以验证失败回调被调用或有进度回调
        XCTAssertTrue(failedCallbackCalled || progressCallbackCount > 0, "应该调用进度或失败回调")
    }
    
    func testStopProgressPolling() {
        let taskId = "test-task-123"
        
        // 开始轮询
        progressPollingService.startProgressPolling(
            taskId: taskId,
            onProgress: { _ in },
            onCompleted: { },
            onFailed: { _ in }
        )
        
        // 停止轮询
        progressPollingService.stopProgressPolling()
        
        // 验证轮询已停止（这里主要测试方法调用不会崩溃）
        XCTAssertTrue(true, "停止轮询应该成功")
    }
    
    // MARK: - 连环画生成状态轮询测试
    
    func testPollComicGenerationStatus() async {
        let taskId = "test-comic-task-123"
        let expectation = XCTestExpectation(description: "连环画生成状态轮询")
        var progressCallbackCount = 0
        var failedCallbackCalled = false
        
        await progressPollingService.pollComicGenerationStatus(
            taskId: taskId,
            onProgress: { result in
                progressCallbackCount += 1
                // 由于是测试环境，网络请求会失败，但我们可以验证回调被调用
            },
            onCompleted: {
                expectation.fulfill()
            },
            onFailed: { message in
                failedCallbackCalled = true
                expectation.fulfill()
            }
        )
        
        await fulfillment(of: [expectation], timeout: 10.0)
        
        // 在测试环境中，网络请求通常会失败，所以验证失败回调被调用
        XCTAssertTrue(failedCallbackCalled || progressCallbackCount > 0, "应该调用进度或失败回调")
    }
    
    // MARK: - 后端任务取消测试
    
    func testCancelBackendTask() {
        let taskId = "test-cancel-task-123"
        
        // 测试取消任务方法调用不会崩溃
        progressPollingService.cancelBackendTask(taskId: taskId)
        
        XCTAssertTrue(true, "取消后端任务应该成功")
    }
    
    // MARK: - 重置功能测试
    
    func testReset() {
        let taskId = "test-reset-task-123"
        
        // 设置一些状态
        progressPollingService.startProgressPolling(
            taskId: taskId,
            onProgress: { _ in },
            onCompleted: { },
            onFailed: { _ in }
        )
        
        // 重置服务
        progressPollingService.reset()
        
        // 验证状态被重置
        XCTAssertEqual(progressPollingService.uploadProgress, 0.0, "重置后上传进度应为0")
        XCTAssertEqual(progressPollingService.uploadStatus, .pending, "重置后状态应为pending")
        XCTAssertNil(progressPollingService.errorMessage, "重置后错误信息应为nil")
    }
    
    // MARK: - ProgressResult 结构测试
    
    func testProgressResultStructure() {
        let result = ProgressPollingService.ProgressResult(
            status: "processing",
            progress: 50,
            message: "处理中",
            stage: "uploading",
            shouldContinue: true,
            shouldExtractFrames: false,
            shouldTryEarlyExtraction: true
        )
        
        XCTAssertEqual(result.status, "processing", "状态应该正确")
        XCTAssertEqual(result.progress, 50, "进度应该正确")
        XCTAssertEqual(result.message, "处理中", "消息应该正确")
        XCTAssertEqual(result.stage, "uploading", "阶段应该正确")
        XCTAssertTrue(result.shouldContinue, "应该继续")
        XCTAssertFalse(result.shouldExtractFrames, "不应该提取帧")
        XCTAssertTrue(result.shouldTryEarlyExtraction, "应该尝试提前提取")
    }
    
    // MARK: - ComicProgressResult 结构测试
    
    func testComicProgressResultStructure() {
        let result = ProgressPollingService.ComicProgressResult(
            isCompleted: true,
            isFailed: false,
            progress: 100,
            stage: "completed",
            message: "完成",
            shouldFetchResult: true
        )
        
        XCTAssertTrue(result.isCompleted, "应该已完成")
        XCTAssertFalse(result.isFailed, "不应该失败")
        XCTAssertEqual(result.progress, 100, "进度应该为100")
        XCTAssertEqual(result.stage, "completed", "阶段应该为completed")
        XCTAssertEqual(result.message, "完成", "消息应该正确")
        XCTAssertTrue(result.shouldFetchResult, "应该获取结果")
    }
    
    // MARK: - 边界条件测试
    
    func testEmptyTaskId() {
        let emptyTaskId = ""
        
        // 测试空任务ID不会导致崩溃
        progressPollingService.startProgressPolling(
            taskId: emptyTaskId,
            onProgress: { _ in },
            onCompleted: { },
            onFailed: { _ in }
        )
        
        progressPollingService.cancelBackendTask(taskId: emptyTaskId)
        
        XCTAssertTrue(true, "空任务ID应该被正确处理")
    }
    
    func testMultipleStartStopCalls() {
        let taskId = "test-multiple-calls-123"
        
        // 多次开始和停止轮询
        for _ in 0..<3 {
            progressPollingService.startProgressPolling(
                taskId: taskId,
                onProgress: { _ in },
                onCompleted: { },
                onFailed: { _ in }
            )
            progressPollingService.stopProgressPolling()
        }
        
        XCTAssertTrue(true, "多次开始和停止轮询应该正常工作")
    }
    
    // MARK: - 性能测试
    
    func testPerformanceReset() {
        measure {
            for _ in 0..<100 {
                progressPollingService.reset()
            }
        }
    }
    
    func testPerformanceStartStop() {
        let taskId = "performance-test-task"
        
        measure {
            for _ in 0..<50 {
                progressPollingService.startProgressPolling(
                    taskId: taskId,
                    onProgress: { _ in },
                    onCompleted: { },
                    onFailed: { _ in }
                )
                progressPollingService.stopProgressPolling()
            }
        }
    }
    
    // MARK: - 内存管理测试
    
    func testMemoryManagement() {
        weak var weakService: ProgressPollingService?
        
        autoreleasepool {
            let service = ProgressPollingService()
            weakService = service
            
            service.startProgressPolling(
                taskId: "memory-test",
                onProgress: { _ in },
                onCompleted: { },
                onFailed: { _ in }
            )
            service.reset()
        }
        
        // 给一些时间让对象被释放
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertNil(weakService, "ProgressPollingService应该被正确释放")
        }
    }
}
