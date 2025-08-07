import UIKit

/// 方向管理器 - 统一管理应用的方向控制
class OrientationManager {
    static let shared = OrientationManager()
    
    private init() {}
    
    /// 强制横屏方向
    func forceLandscapeOrientation() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
        }
        
        // 设置状态栏方向
        UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
    }
    
    /// 恢复默认方向设置
    func restoreDefaultOrientation() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .all))
        }
        
        // 恢复状态栏方向
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
    }
}