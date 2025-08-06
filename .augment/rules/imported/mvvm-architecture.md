---
type: "always_apply"
---

# iOS MVVM 架构和combine响应式编程指南

## 项目概述

本指南适用于iOS17与iOS18，采用MVVM架构和combin响应式编程，专注于视频上传和连环画生成功能。我们只负责iOS App端逻辑，AI大模型后端由合作方负责。

## 职责范围

### ✅ App端负责部分
- 视频文件选择和验证（5-30分钟限制）
- 设备ID生成（UIDevice.current.identifierForVendor）
- 视频上传到合作方提供的API
- 接收和解析合作方返回的JSON数据
- 本地数据存储和状态管理

### ❌ 不负责的部分
- AI大模型视频分析
- 图像处理和风格化
- 剧本和问题生成
- 服务器端业务逻辑

## MVVM 架构规范

### 1. Models (数据模型)
- 纯数据结构，不包含业务逻辑
- 使用 `@Model` 用于 SwiftData
- 只包含属性，不包含方法
- 包含视频文件信息（时长、大小验证）
- 上传任务状态管理
- API响应数据结构

### 2. ViewModels (视图模型)
- 处理业务逻辑，管理状态
- 使用 `@Observable` 或 `ObservableObject`
- 包含 `@Published` 属性用于状态管理
- 不直接引用视图
- **禁止使用单例模式** (`shared` 静态实例)
- 状态管理与UI逻辑，处理用户交互
- 视频选择、验证、上传状态管理
- 数据绑定，向View提供格式化数据
- 调用Model执行业务操作，订阅数据变化（Combine）
- 错误与加载状态统一处理

#### ViewModel响应式编程规范
- **必须使用@Published**: 所有需要触发UI更新的属性都必须标记为`@Published`
- **计算属性响应式**: 依赖`@Published`属性的计算属性会自动响应变化
- **Combine订阅**: 使用`$property.sink`或`@Published`属性的组合来处理复杂数据流
- **避免手动通知**: 不要手动调用`objectWillChange.send()`，依赖`@Published`自动机制

### 3. Views (视图)
- 纯UI展示，不包含业务逻辑
- SwiftUI开发，@ObservedObject/@StateObject绑定ViewModel
- 通过 `@State` 和 `@Bindable` 管理状态
- 使用 ViewModel 处理业务逻辑
- 组件化、可复用、条件渲染（加载/错误/空数据）
- iOS设备适配（iPhone/iPad）、暗黑模式、主题切换
- 支持视频选择器、权限请求、上传进度展示

## ViewModel 实例化策略

### 推荐方式
1. **按需创建**：每个视图创建独立的ViewModel实例
2. **依赖注入**：通过 `.environment()` 传递ViewModel
3. **生命周期管理**：
   - 短期：使用 `@State` 管理
   - 长期：使用 `@Environment` 或 `@StateObject`

### 禁止方式
- ❌ 使用 `static let shared` 单例模式
- ❌ 在ViewModel中创建全局状态
- ❌ 多个视图共享同一个ViewModel实例

### 正确示例
```swift
// ✅ 正确：按需创建
@State private var viewModel = ItemViewModel()

// ✅ 正确：依赖注入
.environment(ItemViewModel())

// ✅ 正确：响应式ViewModel
class ItemViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var filteredItems: [DisplayItem] = []

    private var cancellables = Set<AnyCancellable>()

    init() {
        $items
            .map { items in
                items.map { DisplayItem(from: $0) }
            }
            .assign(to: &$filteredItems)
    }
}

// ❌ 错误：单例模式
// static let shared = ItemViewModel() // 禁止

// ❌ 错误：非响应式计算属性
// var filteredItems: [DisplayItem] {
//     return items.map { DisplayItem(from: $0) }
// }
```

## 数据流与响应式编程

### 基本数据流
View → ViewModel → Service → Model

### Combine响应式数据流
```swift
// ViewModel中的响应式数据处理
class MyViewModel: ObservableObject {
    @Published var sourceData: [DataModel] = []
    @Published var processedData: [DisplayModel] = []

    private var cancellables = Set<AnyCancellable>()

    init() {
        // 响应式数据转换
        $sourceData
            .map { data in
                // 业务逻辑处理
                return data.map { DisplayModel(from: $0) }
            }
            .assign(to: &$processedData)
    }
}
```

### 响应式编程最佳实践
1. **数据源响应**: 使用`@Published`属性作为数据源
2. **自动转换**: 通过`.map`、`.filter`等操作符处理数据
3. **链式操作**: 使用`.assign(to:)`或`.sink`订阅结果
4. **内存管理**: 使用`Set<AnyCancellable>`管理订阅生命周期
5. **错误处理**: 使用`.catch`、`.replaceError`处理错误情况

## 禁止事项
- 在View中直接处理业务逻辑
- 在Model中包含业务逻辑
- 在ViewModel中直接操作UI
- 在View中直接访问数据库
- 使用单例模式创建ViewModel
- 在Model中包含业务逻辑
- 在ViewModel中直接操作UI
- 在View中直接访问数据库

## 技术栈

### 核心技术
- **SwiftUI**：iOS UI开发
- **Combine**：响应式数据流
- **SwiftData**：本地数据持久化
- **URLSession**：网络通信
- **PhotosUI**：系统照片选择器
- **AVFoundation**：视频时长和格式检查

### 开发规范
- 代码规范、类型安全、健壮性、详细注释
- **在增加函数func前先看看其他文件是否已有相关实现**
- 遵循Apple HIG，界面直观易用，专注iOS体验

## 参考资料

- [Apple Human Interface Guidelines](mdc:https:/developer.apple.com/design/human-interface-guidelines)
- [SwiftUI 官方文档](mdc:https:/developer.apple.com/documentation/swiftui)
- [Combine 官方文档](mdc:https:/developer.apple.com/documentation/combine)
- [SwiftData 官方文档](mdc:https:/developer.apple.com/documentation/swiftdata)
- [PhotosUI 官方文档](mdc:https:/developer.apple.com/documentation/photosui)
- [AVFoundation 官方文档](mdc:https:/developer.apple.com/documentation/avfoundation)
- [URLSession 官方文档](mdc:https:/developer.apple.com/documentation/foundation/urlsession)
