# SwiftUI 响应式布局 Cursor Rule（精简版）

## 1. 命名规范

### 视图命名
- 响应式组件使用 `Responsive` 前缀
- 自适应布局使用 `Adaptive` 前缀
- 以 `View` 结尾

```swift
// ✅ 正确
struct UserProfileResponsiveView: View
struct ProductListAdaptiveView: View

// ❌ 避免
struct UserView: View
```

### 变量命名
- 布局相关：`layout` 前缀
- 尺寸相关：`size` 后缀
- 间距相关：`spacing` 后缀

```swift
@State private var layoutWidth: CGFloat
let defaultSpacing: CGFloat
```

## 2. 核心布局原则

### 必须遵守
- **使用相对尺寸**，避免硬编码像素值
- **支持横竖屏切换**，提供不同布局方案
- **核心内容完整显示**，合理分配屏幕空间
- **从 iPhone SE 到 iPad Pro 全设备适配**

### 标准布局结构
```swift
var body: some View {
    GeometryReader { geometry in
        if isLandscape {
            landscapeLayout(geometry)
        } else {
            portraitLayout(geometry)
        }
    }
}
```

## 3. 响应式组件使用规范

### GeometryReader
- 用于需要基于父容器尺寸动态布局的场景
- **避免嵌套使用**
- 仅在必要时使用，注意性能

```swift
// ✅ 正确
GeometryReader { geometry in
    Text("Content")
        .frame(width: geometry.size.width * 0.8)
}
```

### ViewThatFits（iOS 16+）
- 优先使用，替代复杂 if-else
- **从大到小排列候选视图**
- 最后一个作为默认视图

```swift
ViewThatFits {
    FullContentView()      // 优先显示
    SimplifiedContentView() // 空间不足时
    MinimalContentView()   // 默认视图
}
```

### Size Classes
- 使用 `@Environment` 获取尺寸类别
- 基于 `.compact` 和 `.regular` 进行条件布局

```swift
@Environment(\.horizontalSizeClass) var horizontalSizeClass

var body: some View {
    if horizontalSizeClass == .compact {
        compactLayout
    } else {
        regularLayout
    }
}
```

## 4. 布局设计规范

### 横屏布局
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

### 竖屏布局
```swift
VStack(spacing: 0) {
    Spacer().frame(minHeight: 20)

    // 主要内容区域 (30-40%)
    mainContent
        .frame(maxHeight: geometry.size.height * 0.35)

    Spacer().frame(height: 30-40)

    // 次要内容和操作区域
    secondaryContent
    actionArea

    Spacer().frame(minHeight: 40)
}
```

## 5. 性能优化

### 状态管理
- `@State`：视图内部状态
- `@ObservedObject`：外部可观察对象
- `@StateObject`：视图拥有的对象

```swift
// ✅ 正确
@State private var isLoading: Bool
@ObservedObject var viewModel: ContentViewModel
@StateObject private var dataManager = DataManager()
```

### 优化技巧
- 避免过度计算，移至 ViewModel
- 复杂视图使用 `lazy` 加载
- 避免嵌套 GeometryReader

## 6. 示例模板

### 基础响应式布局
```swift
/// 响应式内容卡片视图
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
            Text(content.details)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var regularContentView: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading) {
                Text(content.description)
                Text(content.details)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(content.imageName)
                .resizable()
                .frame(width: 100, height: 100)
        }
    }

    private var footerView: some View {
        HStack {
            Button("Learn More") { }
                .buttonStyle(.bordered)

            Spacer()

            Button(action: {}) {
                Image(systemName: "heart")
            }
        }
    }
}
```

## 7. 测试预览

### 预览配置
```swift
struct ResponsiveViewName_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ResponsiveViewName()
                .previewDevice("iPhone 14")

            ResponsiveViewName()
                .previewDevice("iPad Pro (12.9-inch)")
        }
    }
}
```

## 8. 禁止事项

- ❌ 使用固定像素值布局
- ❌ 忽略设备方向变化
- ❌ 硬编码屏幕尺寸
- ❌ 嵌套 GeometryReader
- ❌ 在单一方法中处理所有布局
- ❌ 内容在小屏幕上显示不全

---

**核心原则**：声明式、自适应、跨设备一致。优先使用 SwiftUI 原生组件，避免手动计算布局。