# SwiftUI 响应式布局规范

## 🎯 核心原则

### 1. 设备方向适配
- **必须支持横竖屏切换**，提供不同的布局方案
- **使用统一的方向检测机制**，确保准确性
- **布局切换要流畅**，避免卡顿和错位

### 2. 屏幕尺寸适配
- **使用相对尺寸**而非固定像素值
- **基于 GeometryReader 获取实时屏幕信息**
- **支持从 iPhone SE 到 iPad Pro 的全设备范围**

### 3. 内容优先原则
- **核心内容在任何设备上都要完整显示**
- **合理分配屏幕空间**，避免浪费
- **保持视觉层次和可读性**

## 🔧 技术实现规范

### 1. 方向检测标准实现

```swift
// 统一的方向检测机制
private var isLandscape: Bool {
    UIDevice.current.orientation.isLandscape ||
    UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first?.interfaceOrientation.isLandscape == true
}
```

**要求：**
- 所有需要响应式布局的视图都必须使用此检测方式
- 支持多窗口场景（iPad 分屏）
- 双重检测确保准确性

### 2. 布局切换标准结构

```swift
var body: some View {
    ZStack {
        // 背景层
        backgroundView
        
        GeometryReader { geometry in
            if isLandscape {
                landscapeLayout(geometry)
            } else {
                portraitLayout(geometry)
            }
        }
    }
    .onAppear {
        AppDelegate.orientationLock = .all
    }
}
```

**要求：**
- 使用 `GeometryReader` 获取屏幕尺寸
- 条件渲染不同布局
- 传递 geometry 参数用于响应式计算
- 设置方向锁定支持

### 3. 布局方法命名规范

```swift
// MARK: - 布局扩展
extension YourView {
    /// 横屏布局
    @ViewBuilder
    private func landscapeLayout(_ geometry: GeometryProxy) -> some View {
        // 横屏布局实现
    }
    
    /// 竖屏布局  
    @ViewBuilder
    private func portraitLayout(_ geometry: GeometryProxy) -> some View {
        // 竖屏布局实现
    }
}
```

**要求：**
- 使用 `@ViewBuilder` 修饰符
- 方法名统一为 `landscapeLayout` 和 `portraitLayout`
- 接收 `GeometryProxy` 参数
- 添加清晰的注释说明

## 📐 布局设计规范

### 1. 横屏布局设计原则

#### 空间分配策略
```swift
HStack(spacing: 20-30) {
    // 主内容区域 (60-70%)
    mainContentArea
        .frame(width: geometry.size.width * 0.65)
    
    // 辅助内容区域 (25-35%)  
    auxiliaryContentArea
        .frame(width: geometry.size.width * 0.30)
}
```

#### 标准比例分配
| 内容类型 | 主区域比例 | 辅助区域比例 | 间距 |
|----------|------------|--------------|------|
| 图文展示 | 60-65% | 30-35% | 20-30pt |
| 媒体播放 | 65-70% | 25-30% | 20-30pt |
| 表单输入 | 50-55% | 40-45% | 15-25pt |

### 2. 竖屏布局设计原则

#### 垂直空间分配
```swift
VStack(spacing: 0) {
    // 顶部弹性空间
    Spacer().frame(minHeight: 20)
    
    // 主要内容区域 (30-40% 屏幕高度)
    mainContent
        .frame(maxHeight: geometry.size.height * 0.35)
    
    // 固定间距
    Spacer().frame(height: 30-40)
    
    // 次要内容区域
    secondaryContent
    
    // 固定间距  
    Spacer().frame(height: 40-50)
    
    // 操作区域
    actionArea
    
    // 底部弹性空间
    Spacer().frame(minHeight: 40)
}
```

#### 标准高度分配
| 内容区域 | 高度比例 | 最小间距 | 用途 |
|----------|----------|----------|------|
| 主要内容 | 30-40% | - | 图片、视频等核心内容 |
| 次要内容 | 自适应 | 30pt | 文字描述、详情 |
| 操作区域 | 固定尺寸 | 40pt | 按钮、控件 |
| 弹性空间 | 自适应 | 20pt/40pt | 顶部/底部留白 |

### 3. 响应式尺寸计算

#### 字体大小适配
```swift
// 横屏字体（紧凑布局）
.font(.custom("FontName", size: 20-24))

// 竖屏字体（宽松布局）  
.font(.custom("FontName", size: 24-28))
```

#### 组件尺寸适配
```swift
// 按钮尺寸
// 横屏：较小尺寸
.frame(width: 200-220, height: 40-44)

// 竖屏：较大尺寸
.frame(width: 240-260, height: 44-48)
```

## 🎨 视觉设计规范

### 1. 间距系统

#### 标准间距值
| 间距类型 | 横屏 | 竖屏 | 用途 |
|----------|------|------|------|
| 组件间距 | 15-25pt | 20-30pt | 相关元素间距 |
| 区域间距 | 20-30pt | 30-40pt | 不同区域间距 |
| 边缘间距 | 15-20pt | 20pt | 屏幕边缘间距 |
| 弹性间距 | 最小20pt | 最小20pt/40pt | 顶部/底部留白 |

#### 间距实现方式
```swift
// 固定间距
Spacer().frame(height: 30)

// 弹性间距
Spacer().frame(minHeight: 20)

// 组件内边距
.padding(.horizontal, 20)
.padding(.vertical, 15)
```

### 2. 阴影和视觉效果

```swift
// 标准阴影效果
.shadow(radius: 8-12)

// 卡片阴影
.shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
```

## 📱 设备适配规范

### 1. 支持设备列表

#### iPhone 系列
- iPhone SE (375×667) - 最小屏幕
- iPhone 15 (390×844) - 标准屏幕
- iPhone 15 Plus (430×932) - 大屏幕  
- iPhone 15 Pro Max (430×932) - 最大屏幕

#### iPad 系列
- iPad mini (768×1024) - 最小 iPad
- iPad Air (820×1180) - 标准 iPad
- iPad Pro 11" (834×1194) - 中等 iPad
- iPad Pro 12.9" (1024×1366) - 最大 iPad

### 2. 断点设计

```swift
// 基于屏幕宽度的断点
private var screenSize: ScreenSize {
    let width = UIScreen.main.bounds.width
    switch width {
    case 0..<400: return .small      // iPhone SE
    case 400..<450: return .medium   // iPhone 标准
    case 450..<500: return .large    // iPhone Plus
    case 500..<800: return .xlarge   // iPhone Pro Max
    default: return .tablet          // iPad
    }
}
```

## ✅ 实现检查清单

### 开发阶段
- [ ] 实现统一的方向检测机制
- [ ] 创建独立的横竖屏布局方法
- [ ] 使用 GeometryReader 获取屏幕信息
- [ ] 采用相对尺寸而非固定值
- [ ] 设置合适的间距和留白
- [ ] 添加方向锁定支持

### 测试阶段
- [ ] 在所有支持设备上测试
- [ ] 验证横竖屏切换流畅性
- [ ] 检查内容完整显示
- [ ] 确认视觉效果一致性
- [ ] 测试极端尺寸设备

### 代码审查
- [ ] 布局方法命名规范
- [ ] 注释清晰完整
- [ ] 代码结构清晰
- [ ] 无硬编码尺寸值
- [ ] 遵循项目架构规范

## 🚫 禁止事项

### 1. 布局禁忌
- ❌ 使用固定像素值进行布局
- ❌ 忽略设备方向变化
- ❌ 硬编码屏幕尺寸
- ❌ 不考虑内容溢出

### 2. 代码禁忌  
- ❌ 在单一方法中处理所有布局
- ❌ 不使用 GeometryReader 获取尺寸
- ❌ 方向检测不准确
- ❌ 缺少布局切换动画

### 3. 设计禁忌
- ❌ 内容在小屏幕上显示不全
- ❌ 大屏幕上内容过于分散
- ❌ 横竖屏视觉差异过大
- ❌ 忽略用户体验一致性

## 📚 参考资源

- [Apple Human Interface Guidelines - Layout](https://developer.apple.com/design/human-interface-guidelines/layout)
- [SwiftUI GeometryReader 文档](https://developer.apple.com/documentation/swiftui/geometryreader)
- [iOS 设备屏幕规格](https://www.ios-resolution.com/)
- [响应式设计最佳实践](https://web.dev/responsive-web-design-basics/)

---

# SwiftUI 响应式布局 Cursor Rule

## 1. 命名规范

### 视图命名
- 使用描述性名词或名词短语，以 `View` 结尾
- 响应式组件使用 `Responsive` 前缀
- 自适应布局使用 `Adaptive` 前缀

```swift
// ✅ 良好命名
struct UserProfileResponsiveView: View
struct ProductListAdaptiveView: View
struct DashboardCardView: View

// ❌ 避免命名
struct UserView: View
struct ProductV: View
```

### 变量和常量命名
- 布局相关变量使用 `layout` 前缀
- 尺寸相关变量使用 `size` 后缀
- 间距相关变量使用 `spacing` 后缀

```swift
// ✅ 良好命名
@State private var layoutWidth: CGFloat
@State private var cardSize: CGSize
let defaultSpacing: CGFloat

// ❌ 避免命名
@State private var w: CGFloat
@State private var size: CGSize
let space: CGFloat
```

## 2. 代码结构规范

### 文件结构
```swift
//
//  FileName.swift
//  ProjectName
//
//  Created by Author on Date.
//  Copyright © Year Company. All rights reserved.
//

import SwiftUI

// MARK: - Main View
struct ResponsiveViewName: View {
    // MARK: - Properties
    @State private var stateVariables
    @Environment private var environmentVariables

    // MARK: - Body
    var body: some View {
        // Main layout container
    }
}

// MARK: - Preview
struct ResponsiveViewName_Previews: PreviewProvider {
    static var previews: some View {
        ResponsiveViewName()
            .previewDevice("iPhone 14")
            .previewDisplayName("iPhone 14")

        ResponsiveViewName()
            .previewDevice("iPad Pro (12.9-inch)")
            .previewDisplayName("iPad Pro")
    }
}

// MARK: - Subviews/Components
extension ResponsiveViewName {
    private func componentView() -> some View {
        // Component implementation
    }
}
```

### 响应式布局结构
```swift
var body: some View {
    GeometryReader { geometry in
        VStack(spacing: defaultSpacing) {
            headerView
                .frame(height: geometry.size.height * 0.2)

            contentView
                .frame(maxHeight: geometry.size.height * 0.6)

            footerView
                .frame(height: geometry.size.height * 0.2)
        }
        .padding()
    }
}
```

## 3. 响应式组件使用规范

### GeometryReader 使用规则
- **优先使用**：当需要基于父容器尺寸进行动态布局时
- **避免嵌套**：不要在 GeometryReader 内部再嵌套 GeometryReader
- **性能优化**：仅在必要时使用，避免过度使用导致性能问题

```swift
// ✅ 正确使用
GeometryReader { geometry in
    VStack {
        Text("Content")
            .frame(width: geometry.size.width * 0.8)
    }
}

// ❌ 避免使用
GeometryReader { outerGeo in
    GeometryReader { innerGeo in
        // 嵌套 GeometryReader 导致性能问题
    }
}
```

### ViewThatFits 使用规则
- **iOS 16+**：优先使用 ViewThatFits 替代复杂的 if-else 判断
- **顺序重要**：从大到小排列候选视图
- **默认视图**：最后一个视图作为默认选项

```swift
// ✅ 正确使用
ViewThatFits {
    // 优先显示完整版本
    FullContentView()

    // 空间不足时显示简化版本
    SimplifiedContentView()

    // 最后显示最小版本
    MinimalContentView()
}

// ❌ 避免使用
ViewThatFits {
    MinimalContentView()  // 小视图放在前面会优先显示
    FullContentView()    // 大视图可能永远不会显示
}
```

### Size Classes 使用规则
- **环境变量**：使用 @Environment 获取尺寸类别
- **条件布局**：基于尺寸类别进行差异化布局
- **默认处理**：始终提供默认布局方案

```swift
@Environment(\.horizontalSizeClass) var horizontalSizeClass
@Environment(\.verticalSizeClass) var verticalSizeClass

var body: some View {
    if horizontalSizeClass == .compact {
        // iPhone 竖屏布局
        compactLayout
    } else {
        // iPad 或横屏布局
        regularLayout
    }
}
```

### Stack 使用规则
- **VStack**：垂直排列，适合列表、表单
- **HStack**：水平排列，适合导航栏、按钮组
- **ZStack**：叠加排列，适合背景、浮层

```swift
// ✅ 正确使用
VStack(alignment: .leading, spacing: 16) {
    headerView
    contentView
    footerView
}

HStack(spacing: 12) {
    leadingButton
    Spacer()
    trailingButton
}

ZStack {
    backgroundView
    foregroundView
}
```

## 4. 注释和文档规范

### 视图文档注释
```swift
/// 响应式用户资料卡片视图
///
/// 根据可用空间自动调整布局：
/// - 大屏幕：显示完整信息和头像
/// - 中屏幕：显示简化信息和头像
/// - 小屏幕：仅显示必要信息
///
/// - Parameters:
///   - user: 用户数据模型
///   - isCompact: 是否使用紧凑布局
struct UserProfileResponsiveCardView: View {
    let user: User
    @State private var isCompact: Bool = false

    var body: some View {
        // Implementation
    }
}
```

### 布局逻辑注释
```swift
// MARK: - Responsive Layout Logic
private var responsiveLayout: some View {
    GeometryReader { geometry in
        // 根据屏幕宽度决定布局方式
        if geometry.size.width > 600 {
            // iPad 或大屏设备：使用两列布局
            twoColumnLayout
        } else if geometry.size.width > 400 {
            // 中等屏幕：使用单列布局
            singleColumnLayout
        } else {
            // 小屏幕：使用紧凑布局
            compactLayout
        }
    }
}
```

## 5. 性能优化规范

### 状态管理
- **@State**：仅用于视图内部状态
- **@ObservedObject**：用于外部可观察对象
- **@StateObject**：用于视图拥有的可观察对象

```swift
// ✅ 正确使用
@State private var isLoading: Bool
@ObservedObject var viewModel: ContentViewModel
@StateObject private var dataManager = DataManager()

// ❌ 避免使用
@State private var viewModel = ContentViewModel()  // 应该使用 @StateObject
```

### 布局优化
- **避免过度计算**：将复杂计算移至 ViewModel
- **使用 lazy 加载**：对于复杂视图使用懒加载
- **缓存计算结果**：使用 @memoization 或缓存机制

```swift
// ✅ 优化后的布局
private lazy var complexView: some View = {
    // 复杂视图的懒加载
    return ComplexView()
}()

// 缓存计算结果
private func calculateLayoutSize(for geometry: GeometryProxy) -> CGSize {
    // 缓存计算逻辑
    return CGSize(width: geometry.size.width * 0.8, height: geometry.size.height * 0.6)
}
```

---

**规范版本**：v2.0
**制定日期**：2025-01-02
**适用范围**：FrameWeavers iOS 项目


## 6. 示例代码模板

### 基础响应式布局模板
```swift
/// 响应式内容卡片视图
/// 根据可用空间自动调整布局和内容显示
struct ResponsiveContentCardView: View {
    let content: ContentModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 16) {
                headerView
                
                if horizontalSizeClass == .compact {
                    compactContentView
                } else {
                    regularContentView
                }
                
                footerView
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Subviews
    private var headerView: some View {
        Text(content.title)
            .font(.title2)
            .fontWeight(.bold)
    }
    
    private var compactContentView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(content.description)
                .font(.body)
                .lineLimit(3)
            
            Text(content.details)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var regularContentView: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(content.description)
                    .font(.body)
                
                Text(content.details)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(content.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
        }
    }
    
    private var footerView: some View {
        HStack {
            Button(action: {}) {
                Text("Learn More")
                    .fontWeight(.medium)
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "heart")
            }
            .buttonStyle(.borderless)
        }
    }
}
```

### 高级响应式布局模板
```swift
/// 高级响应式仪表板视图
/// 支持多种屏幕尺寸和方向的动态布局
struct AdvancedResponsiveDashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    var body: some View {
        GeometryReader { geometry in
            ViewThatFits {
                // 大屏幕完整布局
                fullDashboardLayout

                // 中等屏幕简化布局
                simplifiedDashboardLayout

                // 小屏幕紧凑布局
                compactDashboardLayout
            }
        }
        .onAppear {
            viewModel.loadData()
        }
    }

    // MARK: - Layout Variants
    private var fullDashboardLayout: some View {
        VStack(spacing: 20) {
            headerSection

            HStack(spacing: 16) {
                mainContentSection
                sidebarSection
            }

            footerSection
        }
        .padding()
    }

    private var simplifiedDashboardLayout: some View {
        VStack(spacing: 16) {
            headerSection

            mainContentSection

            sidebarSection

            footerSection
        }
        .padding()
    }

    private var compactDashboardLayout: some View {
        ScrollView {
            VStack(spacing: 12) {
                headerSection

                mainContentSection

                sidebarSection

                footerSection
            }
            .padding()
        }
    }

    // MARK: - Sections
    private var headerSection: some View {
        HStack {
            Text("Dashboard")
                .font(.largeTitle)
                .fontWeight(.bold)

            Spacer()

            Button(action: {}) {
                Image(systemName: "bell")
            }
        }
    }

    private var mainContentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Main Content")
                .font(.headline)

            // Main content cards
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(viewModel.mainContentItems) { item in
                    ContentCardView(item: item)
                }
            }
        }
    }

    private var sidebarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sidebar")
                .font(.headline)

            ForEach(viewModel.sidebarItems) { item in
                SidebarItemView(item: item)
            }
        }
    }

    private var footerSection: some View {
        HStack {
            Text("Last updated: \(viewModel.lastUpdated)")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Button("Refresh") {
                viewModel.loadData()
            }
            .buttonStyle(.bordered)
        }
    }
}
```

## 7. 测试和预览规范

### 预览设备配置
```swift
struct ResponsiveViewName_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // iPhone 预览
            ResponsiveViewName()
                .previewDevice("iPhone 14")
                .previewDisplayName("iPhone 14")
            
            ResponsiveViewName()
                .previewDevice("iPhone 14 Pro Max")
                .previewDisplayName("iPhone 14 Pro Max")
            
            // iPad 预览
            ResponsiveViewName()
                .previewDevice("iPad Pro (12.9-inch)")
                .previewDisplayName("iPad Pro")
            
            ResponsiveViewName()
                .previewDevice("iPad mini (6th generation)")
                .previewDisplayName("iPad mini")
            
            // Mac 预览
            ResponsiveViewName()
                .previewDevice("Mac")
                .previewDisplayName("Mac")
        }
    }
}
```

### 测试用例模板
```swift
import XCTest
@testable import YourApp

class ResponsiveLayoutTests: XCTestCase {
    
    func testResponsiveViewLayout() {
        // 测试不同尺寸下的布局行为
        let view = ResponsiveViewName()
        
        // 测试紧凑布局
        let compactSize = CGSize(width: 320, height: 568)
        let compactView = view.frame(width: compactSize.width, height: compactSize.height)
        
        // 测试常规布局
        let regularSize = CGSize(width: 768, height: 1024)
        let regularView = view.frame(width: regularSize.width, height: regularSize.height)
        
        // 验证布局正确性
        XCTAssertNotNil(compactView)
        XCTAssertNotNil(regularView)
    }
    
    func testViewThatFitsBehavior() {
        // 测试 ViewThatFits 的选择逻辑
        let view = ViewThatFits {
            Text("Very long text that may not fit")
            Text("Short text")
        }
        
        // 在小空间下应该选择短文本
        let smallSize = CGSize(width: 100, height: 50)
        let smallView = view.frame(width: smallSize.width, height: smallSize.height)
        
        // 在大空间下应该选择长文本
        let largeSize = CGSize(width: 300, height: 100)
        let largeView = view.frame(width: largeSize.width, height: largeSize.height)
        
        XCTAssertNotNil(smallView)
        XCTAssertNotNil(largeView)
    }
}
```
