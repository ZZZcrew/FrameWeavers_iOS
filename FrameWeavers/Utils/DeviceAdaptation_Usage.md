# DeviceAdaptation 使用指南

## 概述

`DeviceAdaptation` 是一个专门用于iOS设备适配的工具类，提供了统一的屏幕尺寸检测和响应式布局支持。

## 核心功能

### 1. 屏幕尺寸检测

```swift
GeometryReader { geometry in
    // 检测屏幕尺寸类型
    let screenSize = DeviceAdaptation.screenSize(for: geometry)
    
    // 检测是否为小屏幕
    let isSmall = DeviceAdaptation.isSmallScreen(geometry)
    
    // 检测是否为大屏幕
    let isLarge = DeviceAdaptation.isLargeScreen(geometry)
    
    // 检测设备类型
    let deviceType = DeviceAdaptation.deviceType // .iPhone 或 .iPad
}
```

### 2. 响应式尺寸计算

#### 图标尺寸
```swift
Image("icon-home")
    .frame(
        width: DeviceAdaptation.iconSize(
            geometry: geometry,
            baseRatio: 0.25,        // 基础比例
            maxSize: 120,           // 最大尺寸
            smallScreenRatio: 0.2   // 小屏幕比例
        )
    )
```

#### 字体大小
```swift
Text("标题")
    .font(.custom("STKaiti", size: DeviceAdaptation.fontSize(
        geometry: geometry,
        baseRatio: 0.045,
        maxSize: 18,
        smallScreenMultiplier: 0.9
    )))
```

#### 行间距
```swift
Text("多行文本")
    .lineSpacing(DeviceAdaptation.lineSpacing(
        geometry: geometry,
        baseRatio: 0.012,
        minSpacing: 3
    ))
```

### 3. 响应式间距

#### 使用 responsiveSpacer
```swift
VStack {
    Text("内容1")
    
    // 响应式间距
    DeviceAdaptation.responsiveSpacer(
        geometry: geometry,
        minHeight: 20,
        maxHeight: 40,
        smallScreenRatio: 0.5  // 小屏幕时为原来的50%
    )
    
    Text("内容2")
}
```

#### 使用 spacing 方法
```swift
VStack(spacing: DeviceAdaptation.spacing(
    geometry: geometry,
    baseSpacing: 20,
    smallScreenMultiplier: 0.6
)) {
    // 内容
}
```

### 4. SwiftUI 扩展方法

#### 响应式内边距
```swift
Text("内容")
    .responsiveSpacing(
        geometry,
        baseSpacing: 16,
        smallScreenMultiplier: 0.7
    )
```

#### 响应式字体
```swift
Text("标题")
    .responsiveFont(
        geometry,
        family: "STKaiti",
        baseRatio: 0.045,
        maxSize: 18,
        smallScreenMultiplier: 0.9
    )
```

## 实际应用示例

### 示例1：欢迎页面布局
```swift
struct WelcomeView: View {
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // 响应式顶部间距
                DeviceAdaptation.responsiveSpacer(
                    geometry: geometry,
                    minHeight: 20,
                    maxHeight: 40
                )
                
                // 响应式图标
                Image("icon")
                    .frame(
                        width: DeviceAdaptation.iconSize(
                            geometry: geometry,
                            baseRatio: 0.25,
                            maxSize: 120,
                            smallScreenRatio: 0.2
                        )
                    )
                
                // 响应式文字
                Text("欢迎文字")
                    .responsiveFont(
                        geometry,
                        family: "STKaiti",
                        baseRatio: 0.045,
                        maxSize: 18
                    )
                    .lineSpacing(DeviceAdaptation.lineSpacing(geometry: geometry))
            }
        }
    }
}
```

### 示例2：结果页面布局
```swift
struct ResultView: View {
    var body: some View {
        GeometryReader { geometry in
            if DeviceAdaptation.isSmallScreen(geometry) {
                // 小屏幕布局
                compactLayout(geometry)
            } else {
                // 标准布局
                standardLayout(geometry)
            }
        }
    }
    
    private func compactLayout(_ geometry: GeometryProxy) -> some View {
        VStack(spacing: DeviceAdaptation.spacing(
            geometry: geometry,
            baseSpacing: 15,
            smallScreenMultiplier: 0.6
        )) {
            // 紧凑布局内容
        }
    }
}
```

## 屏幕尺寸分类

| 类型 | 高度范围 | 典型设备 |
|------|----------|----------|
| `.small` | < 700pt | iPhone SE |
| `.medium` | 700-850pt | iPhone 15 |
| `.large` | > 850pt | iPhone 15 Pro Max |
| `.tablet` | iPad | 所有iPad |

## 最佳实践

1. **统一使用工具类**：避免在各个视图中重复编写适配逻辑
2. **渐进式适配**：使用 `minHeight`/`maxHeight` 实现平滑过渡
3. **保持比例**：使用相对比例而非绝对数值
4. **测试覆盖**：在所有目标设备上测试布局效果

## 注意事项

- 所有方法都需要在 `GeometryReader` 内部使用
- 小屏幕适配主要针对 iPhone SE 等设备
- iPad 会被自动识别为 `.tablet` 类型
- 建议在关键布局节点使用响应式方法
