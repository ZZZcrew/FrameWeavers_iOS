import SwiftUI

/// 水印Logo组件 - 显示在页面底部中间，符合现代响应式设计规范
struct WatermarkLogoView: View {
    // MARK: - Environment
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    var body: some View {
        VStack {
            Image("水印logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: adaptiveLogoHeight)
                .opacity(adaptiveOpacity)
        }
    }
}

// MARK: - Adaptive Properties
private extension WatermarkLogoView {
    /// 是否为紧凑尺寸设备
    var isCompact: Bool {
        horizontalSizeClass == .compact
    }
    
    /// 是否为横屏模式
    var isLandscape: Bool {
        verticalSizeClass == .compact
    }
    
    /// 自适应logo高度
    var adaptiveLogoHeight: CGFloat {
        horizontalSizeClass == .regular ? 36 : 30
    }
    
    /// 自适应透明度
    var adaptiveOpacity: Double {
        1.0
    }
}

// MARK: - Preview
struct WatermarkLogoView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // iPhone 16 Pro Max 横屏测试
            VStack {
                Spacer()
                WatermarkLogoView()
            }
            .previewDevice("iPhone 16 Pro Max")
            .previewInterfaceOrientation(.landscapeLeft)
            .previewDisplayName("iPhone 16 Pro Max - 横屏")
            
            // iPad Pro 横屏测试
            VStack {
                Spacer()
                WatermarkLogoView()
            }
            .previewDevice("iPad Pro (12.9-inch) (6th generation)")
            .previewInterfaceOrientation(.landscapeLeft)
            .previewDisplayName("iPad Pro - 横屏")
        }
        .background(Color.gray.opacity(0.2))
    }
}
