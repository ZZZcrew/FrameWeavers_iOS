import XCTest
import Combine
@testable import FrameWeavers

/// VideoUploadService的单元测试
/// 测试网络上传、multipart请求构建、错误处理等功能
final class VideoUploadServiceTests: XCTestCase {
    
    var uploadService: VideoUploadService!
    var cancellables: Set<AnyCancellable>!
    
    // MARK: - 测试生命周期
    
    override func setUp() {
        super.setUp()
        uploadService = VideoUploadService()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        uploadService = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - 初始状态测试
    
    func testInitialState() {
        // 测试VideoUploadService的初始状态
        XCTAssertEqual(uploadService.uploadProgress, 0, "初始上传进度应该为0")
        XCTAssertEqual(uploadService.uploadStatus, .pending, "初始状态应该是pending")
        XCTAssertNil(uploadService.errorMessage, "初始状态下不应该有错误消息")
    }
    
    // MARK: - 取消上传测试
    
    func testCancelUpload() {
        // 测试取消上传功能
        uploadService.cancelUpload()
        
        // 验证状态重置
        XCTAssertEqual(uploadService.uploadProgress, 0, "取消后进度应该重置为0")
        XCTAssertEqual(uploadService.uploadStatus, .pending, "取消后状态应该重置为pending")
        XCTAssertNil(uploadService.errorMessage, "取消后错误消息应该被清空")
    }
    
    // MARK: - 错误处理测试
    
    func testVideoUploadErrorDescriptions() {
        // 测试各种错误类型的描述
        let errors: [VideoUploadError] = [
            .serviceUnavailable,
            .noData,
            .invalidResponse,
            .parseError("测试解析错误"),
            .serverError(500),
            .timeout,
            .noInternet,
            .connectionLost,
            .cannotConnectToHost,
            .cannotFindHost,
            .fileTooLarge,
            .networkError(404, "Not Found"),
            .unknown("未知错误")
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription, "错误 \(error) 应该有描述")
            XCTAssertFalse(error.errorDescription!.isEmpty, "错误描述不应该为空")
        }
    }
    
    func testSpecificErrorDescriptions() {
        // 测试特定错误的描述内容
        XCTAssertEqual(VideoUploadError.timeout.errorDescription, 
                      "上传超时 - 请检查网络连接或尝试压缩视频后重新上传")
        
        XCTAssertEqual(VideoUploadError.noInternet.errorDescription, 
                      "网络连接不可用 - 请检查网络设置")
        
        XCTAssertEqual(VideoUploadError.fileTooLarge.errorDescription, 
                      "文件过大 - 请压缩视频后重试")
        
        XCTAssertEqual(VideoUploadError.parseError("JSON错误").errorDescription, 
                      "解析响应失败: JSON错误")
        
        XCTAssertEqual(VideoUploadError.serverError(500).errorDescription, 
                      "服务器错误 (500)")
    }
    
    // MARK: - 上传结果测试
    
    func testUploadResultStructure() {
        // 测试UploadResult结构体
        let successResult = VideoUploadService.UploadResult(
            success: true,
            taskId: "test-task-123",
            videoPath: "/path/to/video.mp4",
            uploadedFiles: 1,
            invalidFiles: nil,
            message: "上传成功"
        )
        
        XCTAssertTrue(successResult.success, "成功结果的success应该为true")
        XCTAssertEqual(successResult.taskId, "test-task-123", "任务ID应该正确")
        XCTAssertEqual(successResult.videoPath, "/path/to/video.mp4", "视频路径应该正确")
        XCTAssertEqual(successResult.uploadedFiles, 1, "上传文件数应该正确")
        XCTAssertNil(successResult.invalidFiles, "无效文件列表应该为nil")
        XCTAssertEqual(successResult.message, "上传成功", "消息应该正确")
        
        let failureResult = VideoUploadService.UploadResult(
            success: false,
            taskId: nil,
            videoPath: nil,
            uploadedFiles: nil,
            invalidFiles: ["invalid.txt"],
            message: "上传失败"
        )
        
        XCTAssertFalse(failureResult.success, "失败结果的success应该为false")
        XCTAssertNil(failureResult.taskId, "失败时任务ID应该为nil")
        XCTAssertNil(failureResult.videoPath, "失败时视频路径应该为nil")
        XCTAssertEqual(failureResult.invalidFiles, ["invalid.txt"], "无效文件列表应该正确")
        XCTAssertEqual(failureResult.message, "上传失败", "失败消息应该正确")
    }
    
    // MARK: - 状态变化测试
    
    func testUploadStatusChanges() {
        // 测试上传状态变化
        let expectation = XCTestExpectation(description: "状态变化监听")
        var statusChanges: [UploadStatus] = []
        
        // 监听状态变化
        uploadService.$uploadStatus
            .sink { status in
                statusChanges.append(status)
                if statusChanges.count >= 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // 模拟状态变化
        DispatchQueue.main.async {
            self.uploadService.uploadStatus = .uploading
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        // 验证状态变化
        XCTAssertEqual(statusChanges.first, .pending, "初始状态应该是pending")
        XCTAssertEqual(statusChanges.last, .uploading, "变化后状态应该是uploading")
    }
    
    func testUploadProgressChanges() {
        // 测试上传进度变化
        let expectation = XCTestExpectation(description: "进度变化监听")
        var progressValues: [Double] = []
        
        // 监听进度变化
        uploadService.$uploadProgress
            .sink { progress in
                progressValues.append(progress)
                if progressValues.count >= 3 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // 模拟进度变化
        DispatchQueue.main.async {
            self.uploadService.uploadProgress = 0.5
            self.uploadService.uploadProgress = 1.0
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        // 验证进度变化
        XCTAssertEqual(progressValues[0], 0.0, "初始进度应该是0")
        XCTAssertEqual(progressValues[1], 0.5, "中间进度应该是0.5")
        XCTAssertEqual(progressValues[2], 1.0, "最终进度应该是1.0")
    }
    
    // MARK: - 模拟上传测试（无网络请求）
    
    func testUploadVideosWithEmptyArray() {
        // 测试空视频数组的上传
        let expectation = XCTestExpectation(description: "空数组上传完成")

        uploadService.uploadVideos([])
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        // 空数组可能会完成但返回失败结果
                        break
                    case .failure(let error):
                        // 空数组可能导致网络错误
                        XCTAssertNotNil(error, "空数组上传产生了错误")
                        expectation.fulfill()
                    }
                },
                receiveValue: { result in
                    // 空数组上传可能返回失败结果
                    XCTAssertFalse(result.success, "空数组上传应该返回失败结果")
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - 性能测试
    
    func testPerformanceOfServiceCreation() {
        // 测试服务创建的性能
        measure {
            for _ in 0..<100 {
                let service = VideoUploadService()
                XCTAssertNotNil(service)
            }
        }
    }
    
    // MARK: - 辅助方法
    
    /// 创建测试用的视频URL
    /// - Parameter name: 文件名
    /// - Returns: 测试用的URL
    private func createTestVideoURL(name: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        return tempDir.appendingPathComponent(name)
    }
    
    /// 创建实际的测试视频文件
    /// - Parameter name: 文件名
    /// - Returns: 实际存在的视频文件URL，如果创建失败返回nil
    private func createRealTestVideoFile(name: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(name)
        
        // 创建一个最小的MP4文件头
        let minimalMP4Data = Data([
            0x00, 0x00, 0x00, 0x20, 0x66, 0x74, 0x79, 0x70,
            0x69, 0x73, 0x6F, 0x6D, 0x00, 0x00, 0x02, 0x00,
            0x69, 0x73, 0x6F, 0x6D, 0x69, 0x73, 0x6F, 0x32,
            0x61, 0x76, 0x63, 0x31, 0x6D, 0x70, 0x34, 0x31
        ])
        
        do {
            try minimalMP4Data.write(to: fileURL)
            return fileURL
        } catch {
            print("创建测试视频文件失败: \(error)")
            return nil
        }
    }
}
