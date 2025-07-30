---
type: "always_apply"
---

# 📱 移动端响应式设计规范

## 🎯 核心原则

### 1. 使用系统字体和动态类型
- **始终使用系统提供的字体样式**而非固定大小
- **支持动态类型(Dynamic Type)**让用户可调整文字大小
- **使用相对布局**适应不同文字大小

### 2. iOS/iPadOS 字体规范

#### 系统字体大小对照表
| 样式类型 | iOS大小 | iPadOS大小 | 使用场景 |
|---------|---------|------------|----------|
| `.largeTitle` | 34pt | 34pt | 页面大标题 |
| `.title` | 28pt | 28pt | 页面标题 |
| `.title2` | 22pt | 22pt | 次要标题 |
| `.title3` | 20pt | 20pt | 小标题 |
| `.headline` | 17pt | 17pt | 重要文字 |
| `.body` | 17pt | 17pt | 正文内容 |
| `.callout` | 16pt | 16pt | 说明文字 |
| `.subheadline` | 15pt | 15pt | 副标题 |
| `.footnote` | 13pt | 13pt | 脚注 |
| `.caption` | 12pt | 12pt | 图片说明 |
| `.caption2` | 11pt | 11pt | 最小文字 |

#### SF Pro 字体使用规则
- **≥20pt**: 使用 SF Pro Display
- **<20pt**: 使用 SF Pro Text
- **字符间距**: 系统自动调整，无需手动设置

### 3. 响应式布局规范

#### 使用 GeometryReader
```swift
// ✅ 推荐做法
GeometryReader { geometry in
    VStack(spacing: geometry.size.height * 0.05) {
        Text("标题")
            .font(.title)
            .frame(width: geometry.size.width * 0.9)
    }
}

// ❌ 避免做法
VStack(spacing: 40) {
    Text("标题")
        .font(.system(size: 28))
        .frame(width: 350)
}
```

#### 相对尺寸计算
- **间距**: 使用屏幕高度的百分比
- **字体**: 使用 `min(geometry.size.width * 比例, 最大值)` 限制
- **按钮**: 使用 `maxWidth: .infinity` 配合内边距

### 4. 动态类型支持

#### SwiftUI 实现
```swift
// 支持动态类型
Text("内容")
    .font(.body)
    .dynamicTypeSize(...Large) // 限制最大尺寸

// 响应动态类型变化
@Environment(\.dynamicTypeSize) var dynamicTypeSize

var body: some View {
    if dynamicTypeSize.isAccessibilitySize {
        // 大字体布局
    } else {
        // 正常布局
    }
}
```

#### UIKit 实现
```swift
label.adjustsFontForContentSizeCategory = true
label.font = UIFont.preferredFont(forTextStyle: .body)
label.numberOfLines = 0
```

### 5. 设备适配断点

#### iPhone 尺寸分类
- **小屏**: iPhone SE (375×667)
- **标准**: iPhone 13/14/15 (390×844)
- **大屏**: iPhone 14/15 Plus (430×932)
- **最大**: iPhone Pro Max (430×932)

#### iPad 尺寸分类
- **iPad mini**: 768×1024
- **iPad Air**: 820×1180
- **iPad Pro 11"**: 834×1194
- **iPad Pro 12.9"**: 1024×1366

### 6. 实际应用模板

#### 响应式文本组件
```swift
struct ResponsiveText: View {
    let text: String
    let style: Font.TextStyle
    
    var body: some View {
        GeometryReader { geometry in
            Text(text)
                .font(style)
                .lineLimit(nil)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, geometry.size.width * 0.05)
        }
    }
}
```

#### 响应式按钮
```swift
struct ResponsiveButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            Button(action: action) {
                Text(title)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, geometry.size.height * 0.02)
            }
            .padding(.horizontal, geometry.size.width * 0.1)
        }
    }
}
```

### 7. 测试检查清单

#### 动态类型测试
- [ ] 在设置中调整文字大小，检查布局是否正常
- [ ] 使用Xcode预览所有动态类型变体
- [ ] 测试最大辅助功能文字大小

#### 设备适配测试
- [ ] iPhone SE (最小屏幕)
- [ ] iPhone 15 Pro (标准屏幕)
- [ ] iPhone 15 Pro Max (最大屏幕)
- [ ] iPad mini (最小iPad)
- [ ] iPad Pro 12.9" (最大iPad)

#### 横竖屏测试
- [ ] 所有设备方向的布局适配
- [ ] 分屏模式下的iPad布局
- [ ] 多窗口模式支持

### 8. 常见错误避免

#### ❌ 错误做法
- 使用固定字体大小
- 使用绝对布局约束
- 忽略动态类型支持
- 只为单一设备设计

#### ✅ 正确做法
- 使用系统字体样式
- 使用相对布局和百分比
- 全面支持动态类型
- 考虑所有设备尺寸

### 9. 参考资源

- [Apple Human Interface Guidelines - Typography](https://developer.apple.com/design/human-interface-guidelines/typography)
- [WWDC 2024 - Get started with Dynamic Type](https://developer.apple.com/videos/play/wwdc2024/10074/)
- [SF Pro Font Download](https://developer.apple.com/fonts/)
- [iOS Font Size Guidelines](https://www.learnui.design/blog/ios-font-size-guidelines.html)
