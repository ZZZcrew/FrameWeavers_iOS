import SwiftUI
import UIKit

/// 横屏管理器 - 统一处理横屏逻辑，避免重复代码
class OrientationManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isLandscapeForced: Bool = false
    
    // MARK: - Singleton
    static let shared = OrientationManager()
    
    // MARK: - Private Methods
    private init() {}
    
    // MARK: - Public Methods
    
    /// 强制横屏
    func forceLandscapeOrientation() {
        guard !isLandscapeForced else { return }
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
        }
        
        // 设置状态栏方向
        UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
        
        isLandscapeForced = true
    }
    
    /// 恢复默认方向
    func restoreDefaultOrientation() {
        guard isLandscapeForced else { return }
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .all))
        }
        
        // 恢复状态栏方向
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        
        isLandscapeForced = false
    }
}

// MARK: - View Modifier
struct LandscapeOrientationModifier: ViewModifier {
    @StateObject private var orientationManager = OrientationManager.shared
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                orientationManager.forceLandscapeOrientation()
            }
            .onDisappear {
                orientationManager.restoreDefaultOrientation()
            }
    }
}

extension View {
    /// 强制横屏的视图修饰器
    func forceLandscape() -> some View {
        self.modifier(LandscapeOrientationModifier())
    }
}
