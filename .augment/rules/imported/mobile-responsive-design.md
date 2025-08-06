---
type: "always_apply"
---

# 📱 iOS17+ 现代响应式设计规范

**目标系统**: iOS17+, iPadOS17+ (不考虑更低版本)
**核心理念**: 简洁、现代、高效 - 充分利用最新SwiftUI特性

## 🎯 核心原则

### 1. 优先使用现代SwiftUI特性
- **Size Classes** - 替代复杂的设备检测
- **ScrollView** - 替代复杂的GeometryReader布局
- **Environment Values** - 响应系统设置变化
- **Dynamic Type** - 系统级字体缩放支持

### 2. 禁止过度工程化
- ❌ **禁止**自定义设备适配工具类
- ❌ **禁止**复杂的GeometryReader嵌套
- ❌ **禁止**手动计算屏幕尺寸
- ❌ **禁止**固定像素值布局

## 🏗️ 现代布局架构

### 基础响应式模板
```swift
struct ModernResponsiveView: View {
    // MARK: - Environment
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        ScrollView {
            VStack(spacing: adaptiveSpacing) {
                Spacer(minLength: topSpacing)

                // 内容组件
                contentView

                Spacer(minLength: bottomSpacing)
            }
            .padding(.horizontal, horizontalPadding)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Adaptive Properties
private extension ModernResponsiveView {
    var isCompact: Bool {
        horizontalSizeClass == .compact || verticalSizeClass == .compact
    }

    var adaptiveSpacing: CGFloat { isCompact ? 16 : 24 }
    var topSpacing: CGFloat { isCompact ? 20 : 40 }
    var bottomSpacing: CGFloat { isCompact ? 20 : 40 }
    var horizontalPadding: CGFloat { isCompact ? 20 : 40 }
}
```

## 🔤 现代字体系统

### 系统字体样式 (iOS17+)
```swift
// ✅ 推荐：使用系统字体样式
Text("标题").font(.largeTitle)     // 34pt - 页面大标题
Text("标题").font(.title)         // 28pt - 页面标题
Text("标题").font(.title2)        // 22pt - 次要标题
Text("内容").font(.body)          // 17pt - 正文内容
Text("说明").font(.callout)       // 16pt - 说明文字
Text("脚注").font(.footnote)      // 13pt - 脚注
Text("标签").font(.caption)       // 12pt - 图片说明

// ❌ 禁止：固定字体大小
Text("标题").font(.system(size: 28)) // 禁止使用
```

### 动态类型支持
```swift
// ✅ 限制字体大小范围
Text("内容")
    .font(.body)
    .dynamicTypeSize(...DynamicTypeSize.accessibility1) // 限制最大字体

// ✅ 响应动态类型变化
@Environment(\.dynamicTypeSize) var dynamicTypeSize

var adaptiveFont: Font {
    dynamicTypeSize.isAccessibilitySize ? .title3 : .body
}
```

### 自定义字体的现代用法
```swift
// ✅ 支持动态类型的自定义字体
Text("内容")
    .font(.custom("STKaiti", size: 18))
    .dynamicTypeSize(...DynamicTypeSize.large) // 限制范围
```

## 📐 Size Classes 响应式设计

### 基础Size Classes判断
```swift
@Environment(\.horizontalSizeClass) private var horizontalSizeClass
@Environment(\.verticalSizeClass) private var verticalSizeClass

// 简洁的响应式判断
var isCompact: Bool {
    horizontalSizeClass == .compact || verticalSizeClass == .compact
}

// 基于Size Classes的布局
var body: some View {
    if horizontalSizeClass == .compact {
        compactLayout    // iPhone竖屏、iPad分屏
    } else {
        regularLayout    // iPad横屏、iPhone横屏
    }
}
```

### 设备适配策略
- **iPhone**: 主要使用 `.compact` 水平尺寸类
- **iPad**: 主要使用 `.regular` 水平尺寸类
- **分屏/多窗口**: 自动适配为 `.compact`
- **横竖屏**: 通过 `verticalSizeClass` 判断

## 🎨 现代布局组件

### ScrollView + VStack 模式 (推荐)
```swift
// ✅ 现代布局模式 - 简洁高效
ScrollView {
    VStack(spacing: adaptiveSpacing) {
        Spacer(minLength: topSpacing)

        // 内容组件
        welcomeIcon
        welcomeText
        actionButton
        hintText

        Spacer(minLength: bottomSpacing)
    }
    .padding(.horizontal, horizontalPadding)
    .frame(maxWidth: .infinity)
}

// ❌ 旧模式 - 复杂且性能差
GeometryReader { geometry in
    VStack(spacing: 0) {
        DeviceAdaptation.responsiveSpacer(...)  // 禁止
        // 复杂的计算逻辑
    }
}
```

### ViewThatFits 自适应布局 (iOS16+)
```swift
// ✅ 自动选择合适的布局
ViewThatFits {
    // 优先显示完整布局
    HStack(spacing: 20) {
        image
        VStack { title; description }
        actionButton
    }

    // 空间不足时的简化布局
    VStack(spacing: 12) {
        image
        title
        actionButton
    }

    // 最小布局
    VStack(spacing: 8) {
        title
        actionButton
    }
}
```

### 响应式间距和尺寸
```swift
// ✅ 基于Size Classes的响应式属性
private extension View {
    var adaptiveSpacing: CGFloat { isCompact ? 16 : 24 }
    var adaptivePadding: CGFloat { isCompact ? 20 : 40 }
    var adaptiveIconSize: CGFloat { isCompact ? 70 : 90 }
    var adaptiveButtonWidth: CGFloat { isCompact ? 250 : 280 }
}

// ✅ 使用系统间距
VStack(spacing: .systemSpacing) { ... }  // iOS17+
HStack(spacing: .systemSpacing) { ... }
```

## 🧩 实际应用示例

### 完整的现代响应式视图
```swift
struct ModernWelcomeView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        ScrollView {
            VStack(spacing: adaptiveSpacing) {
                Spacer(minLength: topSpacing)

                welcomeIcon
                welcomeText
                actionButton
                hintText

                Spacer(minLength: bottomSpacing)
            }
            .padding(.horizontal, horizontalPadding)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Adaptive Properties
private extension ModernWelcomeView {
    var isCompact: Bool {
        horizontalSizeClass == .compact || verticalSizeClass == .compact
    }

    var adaptiveSpacing: CGFloat { isCompact ? 16 : 24 }
    var topSpacing: CGFloat { isCompact ? 20 : 40 }
    var bottomSpacing: CGFloat { isCompact ? 20 : 40 }
    var horizontalPadding: CGFloat { isCompact ? 20 : 40 }
    var iconSize: CGFloat { isCompact ? 70 : 90 }
}

// MARK: - UI Components
private extension ModernWelcomeView {
    var welcomeIcon: some View {
        Image("icon-home")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: iconSize, height: iconSize)
            .shadow(radius: 10)
    }

    var welcomeText: some View {
        Text("欢迎文字")
            .font(.body)
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
    }

    var actionButton: some View {
        Button("开始") { }
            .frame(maxWidth: isCompact ? 250 : 280)
            .frame(height: 50)
    }

    var hintText: some View {
        Text("提示文字")
            .font(.caption)
            .dynamicTypeSize(...DynamicTypeSize.large)
            .multilineTextAlignment(.center)
    }
}
```

## 🧪 测试与预览

### Xcode预览配置
```swift
#Preview("iPhone") {
    ModernWelcomeView()
        .previewDevice("iPhone 15 Pro")
}

#Preview("iPad") {
    ModernWelcomeView()
        .previewDevice("iPad Pro (12.9-inch)")
}

#Preview("Dynamic Type") {
    ModernWelcomeView()
        .environment(\.dynamicTypeSize, .accessibility1)
}
```

### 测试检查清单
#### 必测项目
- [ ] iPhone 15 Pro (标准)
- [ ] iPhone 15 Pro Max (大屏)
- [ ] iPad Pro 12.9" (平板)
- [ ] 横竖屏切换
- [ ] 动态字体大小调整
- [ ] 分屏模式 (iPad)

#### 动态类型测试
- [ ] 设置 → 显示与亮度 → 文字大小
- [ ] 测试最大辅助功能字体
- [ ] 确保内容不被截断

## ⚠️ 禁止事项

### 绝对禁止
- ❌ 创建自定义设备适配工具类 (如 `DeviceAdaptation`)
- ❌ 使用 `UIDevice.current` 检测设备类型
- ❌ 手动计算屏幕尺寸和比例
- ❌ 使用固定像素值 (如 `width: 350`)
- ❌ 复杂的 `GeometryReader` 嵌套
- ❌ 自定义文字高度缓存类

### 性能禁忌
- ❌ 过度使用 `GeometryReader`
- ❌ 在视图中进行复杂计算
- ❌ 忽略 `@Environment` 的性能优势

## 📚 Apple官方文档
- [Human Interface Guidelines - Layout](https://developer.apple.com/design/human-interface-guidelines/layout)
- [SwiftUI Size Classes](https://developer.apple.com/documentation/swiftui/environmentvalues/horizontalsizeclass)
- [Dynamic Type](https://developer.apple.com/documentation/uikit/uifont/scaling_fonts_automatically)

**总结**: 这套规范基于iOS17+最新特性，摒弃了复杂的自定义适配方案，采用SwiftUI原生的Size Classes和Environment Values，实现简洁、高效、可维护的响应式设计。
