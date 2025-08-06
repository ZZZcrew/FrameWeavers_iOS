import SwiftUI

/// 文字高度缓存类，避免在视图更新时修改状态
/// 提供智能缓存机制，优化文字高度计算性能
class TextHeightCache: ObservableObject {
    private var cachedHeight: CGFloat = 0
    private var lastGeometrySize: CGSize = .zero
    private let tolerance: CGFloat = 1.0
    
    /// 获取文字高度，带智能缓存
    func getHeight(for geometry: GeometryProxy, calculator: (GeometryProxy) -> CGFloat) -> CGFloat {
        let currentSize = geometry.size
        
        let needsRecalculation = cachedHeight <= 0 ||
            abs(currentSize.width - lastGeometrySize.width) > tolerance ||
            abs(currentSize.height - lastGeometrySize.height) > tolerance
        
        if needsRecalculation {
            cachedHeight = calculator(geometry)
            lastGeometrySize = currentSize
        }
        
        return cachedHeight
    }
    
    /// 清除缓存
    func clearCache() {
        cachedHeight = 0
        lastGeometrySize = .zero
    }
}
