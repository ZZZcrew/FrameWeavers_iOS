# SwiftUI 响应式布局规范

## 🎯 核心原则

### 1. 设备方向适配
- 必须支持横竖屏切换，提供不同的布局方案
- 使用统一的方向检测机制，确保准确性
- 布局切换要流畅，避免卡顿和错位

### 2. 屏幕尺寸适配
- 使用相对尺寸而非固定像素值
- 基于 GeometryReader 获取实时屏幕信息
- 支持从 iPhone SE 到 iPad Pro 的全设备范围

### 3. 内容优先原则
- 核心内容在任何设备上都要完整显示
- 合理分配屏幕空间，避免浪费
- 保持视觉层次和可读性

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

### 2. 布局切换标准结构

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

## 📐 布局设计规范

### 1. 横屏布局设计原则

```swift
HStack(spacing: 20) {
    // 主内容区域 (60-70%)
    mainContentArea
        .frame(width: geometry.size.width * 0.65)

    // 辅助内容区域 (25-35%)
    auxiliaryContentArea
        .frame(width: geometry.size.width * 0.30)
}
```

### 2. 竖屏布局设计原则

```swift
VStack(spacing: 0) {
    Spacer().frame(minHeight: 20)

    // 主要内容区域 (30-40% 屏幕高度)
    mainContent
        .frame(maxHeight: geometry.size.height * 0.35)

    Spacer().frame(height: 30)

    // 次要内容区域
    secondaryContent

    Spacer().frame(height: 40)

    // 操作区域
    actionArea

    Spacer().frame(minHeight: 40)
}
```

## 🎨 视觉设计规范

### 间距系统
```swift
// 固定间距
Spacer().frame(height: 30)

// 弹性间距
Spacer().frame(minHeight: 20)

// 组件内边距
.padding(.horizontal, 20)
.padding(.vertical, 15)
```

### 阴影和视觉效果
```swift
// 标准阴影效果
.shadow(radius: 8)

// 卡片阴影
.shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
```

## 📱 设备适配规范

### 支持设备列表
- iPhone SE (375×667) - 最小屏幕
- iPhone 15 (390×844) - 标准屏幕
- iPhone 15 Plus (430×932) - 大屏幕
- iPhone 15 Pro Max (430×932) - 最大屏幕
- iPad mini (768×1024) - 最小 iPad
- iPad Air (820×1180) - 标准 iPad
- iPad Pro 11" (834×1194) - 中等 iPad
- iPad Pro 12.9" (1024×1366) - 最大 iPad

### 断点设计
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

### 测试阶段
- [ ] 在所有支持设备上测试
- [ ] 验证横竖屏切换流畅性
- [ ] 检查内容完整显示

## 🚫 禁止事项

- ❌ 使用固定像素值进行布局
- ❌ 忽略设备方向变化
- ❌ 硬编码屏幕尺寸
- ❌ 不考虑内容溢出
- ❌ 在单一方法中处理所有布局
- ❌ 不使用 GeometryReader 获取尺寸
- ❌ 方向检测不准确

## 📚 参考资源

- [Apple Human Interface Guidelines - Layout](https://developer.apple.com/design/human-interface-guidelines/layout)
- [SwiftUI GeometryReader 文档](https://developer.apple.com/documentation/swiftui/geometryreader)
```
