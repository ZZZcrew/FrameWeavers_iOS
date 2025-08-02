import SwiftUI
import UIKit

/// 设备适配工具类
/// 提供设备尺寸检测和响应式布局支持
struct DeviceAdaptation {
    
    // MARK: - 屏幕尺寸分类
    
    /// 屏幕尺寸类型
    enum ScreenSize {
        case small      // iPhone SE 等小屏幕 (高度 < 700pt)
        case medium     // iPhone 标准尺寸 (700pt - 850pt)
        case large      // iPhone Plus/Pro Max 等大屏幕 (> 850pt)
        case tablet     // iPad 系列
    }
    
    /// 设备类型
    enum DeviceType {
        case iPhone
        case iPad
    }
    
    // MARK: - 静态属性
    
    /// 当前设备类型
    static var deviceType: DeviceType {
        return UIDevice.current.userInterfaceIdiom == .pad ? .iPad : .iPhone
    }
    
    /// 当前屏幕尺寸分类
    static func screenSize(for geometry: GeometryProxy) -> ScreenSize {
        let height = geometry.size.height
        
        if deviceType == .iPad {
            return .tablet
        }
        
        switch height {
        case ..<700:
            return .small
        case 700..<850:
            return .medium
        default:
            return .large
        }
    }
    
    /// 是否为小屏幕设备
    static func isSmallScreen(_ geometry: GeometryProxy) -> Bool {
        return screenSize(for: geometry) == .small
    }
    
    /// 是否为大屏幕设备
    static func isLargeScreen(_ geometry: GeometryProxy) -> Bool {
        let size = screenSize(for: geometry)
        return size == .large || size == .tablet
    }
    
    // MARK: - 响应式尺寸计算
    
    /// 响应式图标尺寸
    /// - Parameters:
    ///   - geometry: 几何信息
    ///   - baseRatio: 基础比例
    ///   - maxSize: 最大尺寸
    ///   - smallScreenRatio: 小屏幕比例（可选）
    /// - Returns: 计算后的尺寸
    static func iconSize(
        geometry: GeometryProxy,
        baseRatio: CGFloat = 0.25,
        maxSize: CGFloat = 120,
        smallScreenRatio: CGFloat? = nil
    ) -> CGFloat {
        let ratio = isSmallScreen(geometry) ? 
            (smallScreenRatio ?? baseRatio * 0.8) : baseRatio
        return min(geometry.size.width * ratio, maxSize)
    }
    
    /// 响应式间距
    /// - Parameters:
    ///   - geometry: 几何信息
    ///   - baseSpacing: 基础间距
    ///   - smallScreenMultiplier: 小屏幕倍数
    /// - Returns: 计算后的间距
    static func spacing(
        geometry: GeometryProxy,
        baseSpacing: CGFloat,
        smallScreenMultiplier: CGFloat = 0.6
    ) -> CGFloat {
        return isSmallScreen(geometry) ? 
            baseSpacing * smallScreenMultiplier : baseSpacing
    }
    
    /// 响应式行间距
    /// - Parameters:
    ///   - geometry: 几何信息
    ///   - baseRatio: 基础比例
    ///   - minSpacing: 最小间距
    /// - Returns: 计算后的行间距
    static func lineSpacing(
        geometry: GeometryProxy,
        baseRatio: CGFloat = 0.012,
        minSpacing: CGFloat = 3
    ) -> CGFloat {
        let ratio = isSmallScreen(geometry) ? baseRatio * 0.67 : baseRatio
        return max(geometry.size.height * ratio, minSpacing)
    }
    
    /// 响应式字体大小
    /// - Parameters:
    ///   - geometry: 几何信息
    ///   - baseRatio: 基础比例
    ///   - maxSize: 最大字体大小
    ///   - smallScreenMultiplier: 小屏幕倍数
    /// - Returns: 计算后的字体大小
    static func fontSize(
        geometry: GeometryProxy,
        baseRatio: CGFloat,
        maxSize: CGFloat,
        smallScreenMultiplier: CGFloat = 0.9
    ) -> CGFloat {
        let ratio = isSmallScreen(geometry) ? 
            baseRatio * smallScreenMultiplier : baseRatio
        return min(geometry.size.width * ratio, maxSize)
    }
    
    // MARK: - 布局辅助方法
    
    /// 创建响应式 Spacer
    /// - Parameters:
    ///   - geometry: 几何信息
    ///   - minHeight: 最小高度
    ///   - maxHeight: 最大高度
    ///   - smallScreenRatio: 小屏幕比例
    /// - Returns: 配置好的 Spacer
    static func responsiveSpacer(
        geometry: GeometryProxy,
        minHeight: CGFloat,
        maxHeight: CGFloat,
        smallScreenRatio: CGFloat = 0.5
    ) -> some View {
        let actualMin = isSmallScreen(geometry) ? 
            minHeight * smallScreenRatio : minHeight
        let actualMax = isSmallScreen(geometry) ? 
            maxHeight * smallScreenRatio : maxHeight
        
        return Spacer()
            .frame(minHeight: actualMin, maxHeight: actualMax)
    }
    
    /// 获取安全的内容高度
    /// - Parameter geometry: 几何信息
    /// - Returns: 可用的内容高度
    static func safeContentHeight(_ geometry: GeometryProxy) -> CGFloat {
        // 预留导航栏和状态栏空间
        let reservedHeight: CGFloat = deviceType == .iPad ? 100 : 80
        return max(geometry.size.height - reservedHeight, 400)
    }
}

// MARK: - SwiftUI 扩展

extension View {
    /// 应用响应式间距
    func responsiveSpacing(
        _ geometry: GeometryProxy,
        baseSpacing: CGFloat,
        smallScreenMultiplier: CGFloat = 0.6
    ) -> some View {
        self.padding(DeviceAdaptation.spacing(
            geometry: geometry,
            baseSpacing: baseSpacing,
            smallScreenMultiplier: smallScreenMultiplier
        ))
    }
    
    /// 应用响应式字体
    func responsiveFont(
        _ geometry: GeometryProxy,
        family: String,
        baseRatio: CGFloat,
        maxSize: CGFloat,
        smallScreenMultiplier: CGFloat = 0.9
    ) -> some View {
        self.font(.custom(family, size: DeviceAdaptation.fontSize(
            geometry: geometry,
            baseRatio: baseRatio,
            maxSize: maxSize,
            smallScreenMultiplier: smallScreenMultiplier
        )))
    }
}
