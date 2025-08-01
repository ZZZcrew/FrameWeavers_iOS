import XCTest
import SwiftData
@testable import FrameWeavers

/// HistoryService 单元测试
/// 测试历史记录服务的各项功能
final class HistoryServiceTests: XCTestCase {

    // MARK: - 测试属性

    var historyService: HistoryService!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    // MARK: - 测试生命周期
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // 创建内存中的测试数据库
        let schema = Schema([HistoryAlbum.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        modelContext = ModelContext(modelContainer)
        
        // 创建测试服务
        historyService = HistoryService(modelContext: modelContext)
    }
    
    override func tearDownWithError() throws {
        historyService = nil
        modelContext = nil
        modelContainer = nil
        try super.tearDownWithError()
    }
    
    // MARK: - 测试数据创建
    
    /// 创建测试用的连环画结果
    private func createTestComicResult(id: String = "test-comic-\(UUID().uuidString)") -> ComicResult {
        return ComicResult(
            comicId: id,
            deviceId: "test-device-123",
            title: "测试连环画",
            originalVideoTitle: "test-video.mp4",
            creationDate: ISO8601DateFormatter().string(from: Date()),
            panelCount: 3,
            panels: [
                ComicPanel(panelNumber: 1, imageUrl: "image1.jpg", narration: "第一页"),
                ComicPanel(panelNumber: 2, imageUrl: "image2.jpg", narration: "第二页"),
                ComicPanel(panelNumber: 3, imageUrl: "image3.jpg", narration: "第三页")
            ],
            finalQuestions: ["问题1", "问题2"]
        )
    }
    
    // MARK: - 保存功能测试
    
    /// 测试保存连环画到历史记录（同步方法）
    func testSaveComicToHistorySync() throws {
        // Given
        let comicResult = createTestComicResult()
        let expectation = XCTestExpectation(description: "保存完成")
        
        // When
        historyService.saveComicToHistory(comicResult) { success in
            // Then
            XCTAssertTrue(success, "保存应该成功")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)

        // 验证保存结果
        let savedAlbums = try historyService.fetchAllHistoryAlbums()
        XCTAssertEqual(savedAlbums.count, 1, "应该有一个保存的画册")
        XCTAssertEqual(savedAlbums.first?.id, comicResult.comicId, "保存的画册ID应该匹配")
    }

    /// 测试保存连环画到历史记录（异步方法）
    func testSaveComicToHistoryAsync() async throws {
        // Given
        let comicResult = createTestComicResult()

        // When
        let success = await historyService.saveComicToHistory(comicResult)
        
        // Then
        XCTAssertTrue(success, "保存应该成功")
        
        // 验证保存结果
        let savedAlbums = try historyService.fetchAllHistoryAlbums()
        XCTAssertEqual(savedAlbums.count, 1, "应该有一个保存的画册")
        XCTAssertEqual(savedAlbums.first?.title, comicResult.title, "保存的画册标题应该匹配")
    }
    
    /// 测试保存重复ID的连环画
    func testSaveComicWithDuplicateId() async throws {
        // Given
        let comicId = "duplicate-test-id"
        let comicResult1 = createTestComicResult(id: comicId)
        let comicResult2 = createTestComicResult(id: comicId)
        
        // When
        let success1 = await historyService.saveComicToHistory(comicResult1)
        let success2 = await historyService.saveComicToHistory(comicResult2)
        
        // Then
        XCTAssertTrue(success1, "第一次保存应该成功")
        XCTAssertFalse(success2, "第二次保存相同ID应该失败")
        
        // 验证只有一个画册被保存
        let savedAlbums = try historyService.fetchAllHistoryAlbums()
        XCTAssertEqual(savedAlbums.count, 1, "应该只有一个画册")
    }
    
    // MARK: - 查询功能测试
    
    /// 测试获取所有历史记录
    func testGetAllHistoryAlbums() async throws {
        // Given
        let comic1 = createTestComicResult(id: "comic-1")
        let comic2 = createTestComicResult(id: "comic-2")
        
        _ = await historyService.saveComicToHistory(comic1)
        _ = await historyService.saveComicToHistory(comic2)
        
        // When
        let albums = try historyService.fetchAllHistoryAlbums()
        
        // Then
        XCTAssertEqual(albums.count, 2, "应该有两个历史记录")
        
        // 验证按创建时间倒序排列
        XCTAssertTrue(albums[0].creationDate >= albums[1].creationDate, "应该按创建时间倒序排列")
    }
    
    /// 测试获取最近的历史记录
    func testGetRecentHistoryAlbums() async throws {
        // Given - 创建5个测试画册
        for i in 1...5 {
            let comic = createTestComicResult(id: "comic-\(i)")
            _ = await historyService.saveComicToHistory(comic)
            // 添加小延迟确保创建时间不同
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
        
        // When
        let recentAlbums = try historyService.fetchRecentHistoryAlbums(limit: 3)
        
        // Then
        XCTAssertEqual(recentAlbums.count, 3, "应该返回3个最近的记录")
        
        // 验证按时间倒序排列
        for i in 0..<(recentAlbums.count - 1) {
            XCTAssertTrue(recentAlbums[i].creationDate >= recentAlbums[i + 1].creationDate,
                         "应该按创建时间倒序排列")
        }
    }
    
    /// 测试根据ID获取历史记录
    func testGetHistoryAlbumById() async throws {
        // Given
        let comicId = "specific-comic-id"
        let comic = createTestComicResult(id: comicId)
        _ = await historyService.saveComicToHistory(comic)
        
        // When
        let foundAlbum = try historyService.fetchHistoryAlbum(by: comicId)
        let notFoundAlbum = try historyService.fetchHistoryAlbum(by: "non-existent-id")
        
        // Then
        XCTAssertNotNil(foundAlbum, "应该找到指定ID的画册")
        XCTAssertEqual(foundAlbum?.id, comicId, "找到的画册ID应该匹配")
        XCTAssertNil(notFoundAlbum, "不存在的ID应该返回nil")
    }
    
    // MARK: - 删除功能测试
    
    /// 测试删除历史记录
    func testDeleteHistoryAlbum() async throws {
        // Given
        let comic = createTestComicResult()
        _ = await historyService.saveComicToHistory(comic)
        
        let savedAlbums = try historyService.fetchAllHistoryAlbums()
        XCTAssertEqual(savedAlbums.count, 1, "应该有一个保存的画册")
        
        let albumToDelete = savedAlbums.first!
        
        // When
        let deleteSuccess = historyService.deleteHistoryAlbum(albumToDelete)
        
        // Then
        XCTAssertTrue(deleteSuccess, "删除应该成功")
        
        let remainingAlbums = try historyService.fetchAllHistoryAlbums()
        XCTAssertEqual(remainingAlbums.count, 0, "删除后应该没有画册")
    }
    
    /// 测试根据ID删除历史记录
    func testDeleteHistoryAlbumById() async throws {
        // Given
        let comicId = "delete-test-id"
        let comic = createTestComicResult(id: comicId)
        _ = await historyService.saveComicToHistory(comic)
        
        // When
        let deleteSuccess = historyService.deleteHistoryAlbum(by: comicId)
        let deleteNonExistent = historyService.deleteHistoryAlbum(by: "non-existent-id")
        
        // Then
        XCTAssertTrue(deleteSuccess, "删除存在的画册应该成功")
        XCTAssertFalse(deleteNonExistent, "删除不存在的画册应该失败")
        
        let remainingAlbums = try historyService.fetchAllHistoryAlbums()
        XCTAssertEqual(remainingAlbums.count, 0, "删除后应该没有画册")
    }
    
    /// 测试清空所有历史记录
    func testClearAllHistory() async throws {
        // Given - 创建多个测试画册
        for i in 1...3 {
            let comic = createTestComicResult(id: "comic-\(i)")
            _ = await historyService.saveComicToHistory(comic)
        }
        
        let initialCount = try historyService.fetchAllHistoryAlbums().count
        XCTAssertEqual(initialCount, 3, "应该有3个画册")
        
        // When
        let clearSuccess = historyService.clearAllHistory()
        
        // Then
        XCTAssertTrue(clearSuccess, "清空应该成功")
        
        let finalCount = try historyService.fetchAllHistoryAlbums().count
        XCTAssertEqual(finalCount, 0, "清空后应该没有画册")
    }
    
    // MARK: - 统计功能测试
    
    /// 测试获取历史记录总数
    func testGetHistoryCount() async throws {
        // Given
        XCTAssertEqual(historyService.getHistoryCount(), 0, "初始应该没有记录")
        
        // When - 添加一些记录
        for i in 1...3 {
            let comic = createTestComicResult(id: "comic-\(i)")
            _ = await historyService.saveComicToHistory(comic)
        }
        
        // Then
        XCTAssertEqual(historyService.getHistoryCount(), 3, "应该有3个记录")
    }
    
    // MARK: - 业务逻辑测试
    
    /// 测试检查连环画是否已存在
    func testIsComicAlreadyExists() async throws {
        // Given
        let comicId = "existence-test-id"
        let comic = createTestComicResult(id: comicId)
        
        // When & Then - 保存前不存在
        XCTAssertFalse(historyService.isComicAlreadyExists(comicId), "保存前应该不存在")
        
        // 保存后存在
        _ = await historyService.saveComicToHistory(comic)
        XCTAssertTrue(historyService.isComicAlreadyExists(comicId), "保存后应该存在")
        
        // 不存在的ID
        XCTAssertFalse(historyService.isComicAlreadyExists("non-existent-id"), "不存在的ID应该返回false")
    }
    
    /// 测试获取历史记录摘要
    func testGetHistorySummary() async throws {
        // Given - 空状态
        var summary = historyService.getHistorySummary()
        XCTAssertEqual(summary.totalCount, 0, "初始总数应该为0")
        XCTAssertFalse(summary.hasHistory, "初始应该没有历史记录")
        XCTAssertNil(summary.lastCreationDate, "初始应该没有最后创建时间")
        XCTAssertTrue(summary.recentTitles.isEmpty, "初始应该没有最近标题")
        
        // When - 添加一些记录
        for i in 1...3 {
            let comic = createTestComicResult(id: "comic-\(i)")
            _ = await historyService.saveComicToHistory(comic)
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms延迟确保时间不同
        }
        
        // Then
        summary = historyService.getHistorySummary()
        XCTAssertEqual(summary.totalCount, 3, "总数应该为3")
        XCTAssertTrue(summary.hasHistory, "应该有历史记录")
        XCTAssertNotNil(summary.lastCreationDate, "应该有最后创建时间")
        XCTAssertEqual(summary.recentTitles.count, 3, "应该有3个最近标题")
        XCTAssertNotNil(summary.formattedLastCreationDate, "应该有格式化的最后创建时间")
    }
}
