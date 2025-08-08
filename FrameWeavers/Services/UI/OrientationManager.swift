import UIKit

/// 方向管理器 - 统一管理应用的方向控制
class OrientationManager {
    static let shared = OrientationManager()
    
    private init() {}
    
    /// 强制横屏方向
    func forceLandscapeOrientation() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            // 已经是横屏则不重复请求，避免不必要的过渡
            if !windowScene.interfaceOrientation.isLandscape {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
            }
        }
    }
    
    /// 恢复默认方向设置
    func restoreDefaultOrientation() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .all))
        }
    }
}