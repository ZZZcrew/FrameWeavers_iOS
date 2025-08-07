import SwiftUI

// MARK: - 公共响应式属性扩展

/// View的响应式属性扩展 - 避免在多个组件中重复定义
extension View {
    /// 条件性应用modifier
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

/// 响应式设计的公共属性
struct ResponsiveProperties {
    let horizontalSizeClass: UserInterfaceSizeClass?
    let verticalSizeClass: UserInterfaceSizeClass?
    
    /// 是否为紧凑布局
    var isCompact: Bool {
        horizontalSizeClass == .compact
    }
    
    /// 是否为横屏模式
    var isLandscape: Bool {
        verticalSizeClass == .compact
    }
    
    /// 响应式圆角半径
    var adaptiveCornerRadius: CGFloat {
        if isLandscape {
            return isCompact ? 6 : 8
        } else {
            return isCompact ? 8 : 10
        }
    }
    
    /// 响应式间距
    var adaptiveSpacing: CGFloat {
        isCompact ? 16 : 24
    }
    
    /// 响应式内边距
    var adaptivePadding: CGFloat {
        isCompact ? 20 : 40
    }
    
    /// 响应式图标尺寸
    var adaptiveIconSize: CGFloat {
        isCompact ? 70 : 90
    }
    
    /// 响应式按钮宽度
    var adaptiveButtonWidth: CGFloat {
        isCompact ? 250 : 280
    }
}

/// 响应式属性的Environment扩展
extension EnvironmentValues {
    /// 获取响应式属性
    var responsiveProperties: ResponsiveProperties {
        ResponsiveProperties(
            horizontalSizeClass: self.horizontalSizeClass,
            verticalSizeClass: self.verticalSizeClass
        )
    }
}

/// ViewModifier形式的响应式属性访问
struct ResponsivePropertiesModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    let content: (ResponsiveProperties) -> any View
    
    func body(content: Content) -> some View {
        let properties = ResponsiveProperties(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass
        )
        
        AnyView(self.content(properties))
    }
}

/// View扩展 - 便于使用响应式属性
extension View {
    /// 使用响应式属性
    func withResponsiveProperties<Content: View>(
        @ViewBuilder content: @escaping (ResponsiveProperties) -> Content
    ) -> some View {
        modifier(ResponsivePropertiesModifier { properties in
            content(properties)
        })
    }
}
