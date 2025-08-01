import XCTest
import AVFoundation
@testable import FrameWeavers

/// VideoSelectionViewModel的单元测试
/// 测试视频选择、验证、PhotosPicker处理等功能
final class VideoSelectionViewModelTests: XCTestCase {
    
    var viewModel: VideoSelectionViewModel!
    
    // MARK: - 测试生命周期
    
    override func setUp() {
        super.setUp()
        // 每个测试开始前创建新的ViewModel实例
        viewModel = VideoSelectionViewModel()
    }
    
    override func tearDown() {
        // 每个测试结束后清理
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - 初始状态测试
    
    func testInitialState() {
        // 测试ViewModel的初始状态是否正确
        XCTAssertTrue(viewModel.selectedVideos.isEmpty, "初始状态下应该没有选择的视频")
        XCTAssertFalse(viewModel.isShowingPicker, "初始状态下不应该显示选择器")
        XCTAssertEqual(viewModel.validationStatus, .pending, "初始验证状态应该是pending")
        XCTAssertNil(viewModel.validationMessage, "初始状态下不应该有验证消息")
        XCTAssertFalse(viewModel.isValidating, "初始状态下不应该在验证中")
        XCTAssertFalse(viewModel.hasSelectedVideos, "初始状态下hasSelectedVideos应该为false")
        XCTAssertNil(viewModel.selectedVideo, "初始状态下selectedVideo应该为nil")
        XCTAssertFalse(viewModel.isValid, "初始状态下isValid应该为false")
        XCTAssertEqual(viewModel.videoCount, 0, "初始状态下视频数量应该为0")
    }
    
    // MARK: - 视频选择测试
    
    func testSelectSingleVideo() {
        // 创建测试用的URL
        let testURL = createTestVideoURL(name: "test1.mp4")
        
        // 选择单个视频
        viewModel.selectVideo(testURL)
        
        // 验证结果
        XCTAssertEqual(viewModel.selectedVideos.count, 1, "应该有1个选择的视频")
        XCTAssertEqual(viewModel.selectedVideos.first, testURL, "选择的视频URL应该正确")
        XCTAssertEqual(viewModel.selectedVideo, testURL, "selectedVideo属性应该返回第一个视频")
        XCTAssertTrue(viewModel.hasSelectedVideos, "hasSelectedVideos应该为true")
        XCTAssertEqual(viewModel.videoCount, 1, "视频数量应该为1")
    }
    
    func testSelectMultipleVideos() {
        // 创建测试用的URL数组
        let testURLs = [
            createTestVideoURL(name: "test1.mp4"),
            createTestVideoURL(name: "test2.mp4"),
            createTestVideoURL(name: "test3.mp4")
        ]
        
        // 选择多个视频
        viewModel.selectVideos(testURLs)
        
        // 验证结果
        XCTAssertEqual(viewModel.selectedVideos.count, 3, "应该有3个选择的视频")
        XCTAssertEqual(viewModel.selectedVideos, testURLs, "选择的视频URL数组应该正确")
        XCTAssertEqual(viewModel.selectedVideo, testURLs.first, "selectedVideo应该返回第一个视频")
        XCTAssertTrue(viewModel.hasSelectedVideos, "hasSelectedVideos应该为true")
        XCTAssertEqual(viewModel.videoCount, 3, "视频数量应该为3")
    }
    
    func testAddVideo() {
        // 先选择一个视频
        let firstURL = createTestVideoURL(name: "test1.mp4")
        viewModel.selectVideo(firstURL)
        
        // 添加第二个视频
        let secondURL = createTestVideoURL(name: "test2.mp4")
        viewModel.addVideo(secondURL)
        
        // 验证结果
        XCTAssertEqual(viewModel.selectedVideos.count, 2, "应该有2个视频")
        XCTAssertEqual(viewModel.selectedVideos[0], firstURL, "第一个视频应该正确")
        XCTAssertEqual(viewModel.selectedVideos[1], secondURL, "第二个视频应该正确")
    }
    
    func testRemoveVideo() {
        // 先选择多个视频
        let testURLs = [
            createTestVideoURL(name: "test1.mp4"),
            createTestVideoURL(name: "test2.mp4"),
            createTestVideoURL(name: "test3.mp4")
        ]
        viewModel.selectVideos(testURLs)
        
        // 移除中间的视频（索引1）
        viewModel.removeVideo(at: 1)
        
        // 验证结果
        XCTAssertEqual(viewModel.selectedVideos.count, 2, "应该剩余2个视频")
        XCTAssertEqual(viewModel.selectedVideos[0], testURLs[0], "第一个视频应该保持不变")
        XCTAssertEqual(viewModel.selectedVideos[1], testURLs[2], "第二个视频应该是原来的第三个")
    }
    
    func testRemoveVideoWithInvalidIndex() {
        // 选择一个视频
        let testURL = createTestVideoURL(name: "test1.mp4")
        viewModel.selectVideo(testURL)
        
        // 尝试移除无效索引的视频
        viewModel.removeVideo(at: 5)
        
        // 验证结果：应该没有变化
        XCTAssertEqual(viewModel.selectedVideos.count, 1, "视频数量应该保持不变")
        XCTAssertEqual(viewModel.selectedVideos.first, testURL, "视频应该保持不变")
    }
    
    func testClearAllVideos() {
        // 先选择多个视频
        let testURLs = [
            createTestVideoURL(name: "test1.mp4"),
            createTestVideoURL(name: "test2.mp4")
        ]
        viewModel.selectVideos(testURLs)
        
        // 清空所有视频
        viewModel.clearAllVideos()
        
        // 验证结果
        XCTAssertTrue(viewModel.selectedVideos.isEmpty, "所有视频应该被清空")
        XCTAssertEqual(viewModel.validationStatus, .pending, "验证状态应该重置为pending")
        XCTAssertNil(viewModel.validationMessage, "验证消息应该被清空")
        XCTAssertFalse(viewModel.hasSelectedVideos, "hasSelectedVideos应该为false")
        XCTAssertNil(viewModel.selectedVideo, "selectedVideo应该为nil")
        XCTAssertEqual(viewModel.videoCount, 0, "视频数量应该为0")
    }
    
    // MARK: - 验证状态测试

    func testValidationStatusChanges() {
        // 创建测试URL
        let testURL = createTestVideoURL(name: "test.mp4")

        // 初始状态应该是pending
        XCTAssertEqual(viewModel.validationStatus, .pending)
        XCTAssertFalse(viewModel.isValid)

        // 选择视频后，验证状态会改变（但由于是模拟URL，可能会失败）
        viewModel.selectVideo(testURL)

        // 验证状态应该不再是pending
        XCTAssertNotEqual(viewModel.validationStatus, .pending)
    }

    func testIsValidProperty() {
        // 初始状态下isValid应该为false
        XCTAssertFalse(viewModel.isValid)

        // 手动设置验证状态为valid
        viewModel.validationStatus = .valid
        XCTAssertTrue(viewModel.isValid)

        // 设置为其他状态
        viewModel.validationStatus = .invalid
        XCTAssertFalse(viewModel.isValid)

        viewModel.validationStatus = .validating
        XCTAssertFalse(viewModel.isValid)
    }

    // MARK: - 边界条件测试

    func testEmptyVideoSelection() {
        // 选择空数组
        viewModel.selectVideos([])

        // 验证结果
        XCTAssertTrue(viewModel.selectedVideos.isEmpty, "选择空数组后应该没有视频")
        XCTAssertFalse(viewModel.hasSelectedVideos, "hasSelectedVideos应该为false")
        XCTAssertEqual(viewModel.videoCount, 0, "视频数量应该为0")
    }

    func testSelectSameVideoMultipleTimes() {
        let testURL = createTestVideoURL(name: "test.mp4")

        // 多次选择同一个视频
        viewModel.selectVideo(testURL)
        viewModel.selectVideo(testURL)
        viewModel.selectVideo(testURL)

        // 应该只有一个视频（因为selectVideo会重置数组）
        XCTAssertEqual(viewModel.selectedVideos.count, 1, "多次选择同一视频应该只有一个")
        XCTAssertEqual(viewModel.selectedVideos.first, testURL, "视频URL应该正确")
    }

    func testAddSameVideoMultipleTimes() {
        let testURL = createTestVideoURL(name: "test.mp4")

        // 多次添加同一个视频
        viewModel.addVideo(testURL)
        viewModel.addVideo(testURL)
        viewModel.addVideo(testURL)

        // 应该有多个相同的视频（addVideo不会去重）
        XCTAssertEqual(viewModel.selectedVideos.count, 3, "多次添加同一视频应该有多个")
        XCTAssertTrue(viewModel.selectedVideos.allSatisfy { $0 == testURL }, "所有视频URL应该相同")
    }

    // MARK: - 性能测试

    func testPerformanceOfSelectingManyVideos() {
        // 创建大量测试URL
        let testURLs = (1...100).map { createTestVideoURL(name: "test\($0).mp4") }

        // 测试选择大量视频的性能
        measure {
            viewModel.selectVideos(testURLs)
        }

        // 验证结果
        XCTAssertEqual(viewModel.selectedVideos.count, 100, "应该选择了100个视频")
    }

    // MARK: - 辅助方法

    /// 创建测试用的视频URL
    /// - Parameter name: 文件名
    /// - Returns: 测试用的URL
    private func createTestVideoURL(name: String) -> URL {
        // 创建临时目录中的测试文件URL
        let tempDir = FileManager.default.temporaryDirectory
        return tempDir.appendingPathComponent(name)
    }

    /// 创建实际的测试视频文件（用于真实的验证测试）
    /// - Parameter name: 文件名
    /// - Returns: 实际存在的视频文件URL，如果创建失败返回nil
    private func createRealTestVideoFile(name: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(name)

        // 创建一个最小的MP4文件头（这不是真正的视频，但可以用于测试）
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
