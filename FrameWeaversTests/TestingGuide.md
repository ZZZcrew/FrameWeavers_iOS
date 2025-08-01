# FrameWeavers 单元测试指南

## 什么是单元测试？

单元测试是对代码中最小可测试单元进行验证的自动化测试。在iOS开发中，我们使用XCTest框架来编写和运行单元测试。

### 单元测试的好处：

1. **验证功能正确性**：确保代码按预期工作
2. **防止回归错误**：修改代码时确保不会破坏现有功能
3. **提高代码质量**：编写可测试的代码通常结构更好
4. **文档作用**：测试用例展示了代码的预期行为
5. **重构信心**：有了测试保护，可以安全地重构代码

## 如何运行测试

### 在Xcode中运行测试：

1. **运行所有测试**：
   - 快捷键：`Cmd + U`
   - 或者：Product → Test

2. **运行单个测试文件**：
   - 在测试文件中，点击类名旁边的菱形按钮
   - 或者右键点击测试文件 → Run Tests

3. **运行单个测试方法**：
   - 点击测试方法旁边的菱形按钮

### 在命令行中运行测试：

```bash
# 运行所有测试
xcodebuild test -project FrameWeavers.xcodeproj -scheme FrameWeavers -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max'

# 只运行特定的测试类
xcodebuild test -project FrameWeavers.xcodeproj -scheme FrameWeavers -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' -only-testing:FrameWeaversTests/VideoSelectionViewModelTests
```

## 测试结果解读

### 测试状态图标：
- ✅ **绿色对勾**：测试通过
- ❌ **红色X**：测试失败
- ⚪ **灰色圆圈**：测试未运行

### 测试失败时：
1. 查看失败信息：Xcode会显示具体的失败原因
2. 检查断言：看看哪个XCTAssert失败了
3. 调试测试：可以在测试方法中设置断点进行调试

## VideoSelectionViewModel测试说明

我们为VideoSelectionViewModel创建了全面的测试，包括：

### 1. 初始状态测试 (`testInitialState`)
验证ViewModel创建时的初始状态是否正确。

### 2. 视频选择功能测试
- `testSelectSingleVideo`：测试选择单个视频
- `testSelectMultipleVideos`：测试选择多个视频
- `testAddVideo`：测试添加视频到现有列表
- `testRemoveVideo`：测试移除指定视频
- `testClearAllVideos`：测试清空所有视频

### 3. 边界条件测试
- `testRemoveVideoWithInvalidIndex`：测试移除无效索引的视频
- `testEmptyVideoSelection`：测试选择空视频列表
- `testSelectSameVideoMultipleTimes`：测试重复选择同一视频

### 4. 验证状态测试
- `testValidationStatusChanges`：测试验证状态变化
- `testIsValidProperty`：测试isValid属性的正确性

### 5. 性能测试
- `testPerformanceOfSelectingManyVideos`：测试选择大量视频的性能

## 测试最佳实践

### 1. 测试命名规范
```swift
func test[功能描述]() {
    // 测试代码
}
```

### 2. 测试结构（AAA模式）
```swift
func testExample() {
    // Arrange（准备）：设置测试数据和环境
    let testData = "test"
    
    // Act（执行）：执行要测试的操作
    let result = viewModel.someMethod(testData)
    
    // Assert（断言）：验证结果是否符合预期
    XCTAssertEqual(result, expectedValue)
}
```

### 3. 常用断言方法
```swift
XCTAssertTrue(condition)           // 验证条件为真
XCTAssertFalse(condition)          // 验证条件为假
XCTAssertEqual(a, b)               // 验证两个值相等
XCTAssertNotEqual(a, b)            // 验证两个值不相等
XCTAssertNil(value)                // 验证值为nil
XCTAssertNotNil(value)             // 验证值不为nil
XCTAssertGreaterThan(a, b)         // 验证a大于b
XCTAssertLessThan(a, b)            // 验证a小于b
```

## 下一步

1. **运行现有测试**：先运行VideoSelectionViewModelTests，确保所有测试通过
2. **添加更多测试**：为其他ViewModel和Service类添加测试
3. **集成测试**：测试不同组件之间的交互
4. **UI测试**：使用XCUITest测试用户界面

## 常见问题

### Q: 测试失败了怎么办？
A: 
1. 仔细阅读失败信息
2. 检查测试逻辑是否正确
3. 确认被测试的代码是否有bug
4. 使用断点调试测试代码

### Q: 如何测试异步代码？
A: 使用XCTestExpectation：
```swift
func testAsyncMethod() {
    let expectation = XCTestExpectation(description: "异步操作完成")
    
    viewModel.asyncMethod { result in
        XCTAssertNotNil(result)
        expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 5.0)
}
```

### Q: 如何模拟网络请求？
A: 使用Mock对象或URLProtocol来模拟网络响应，避免在测试中进行真实的网络请求。
