import SwiftUI

/// 连环画阅读菜单栏组件 - 类似Apple Books的阅读界面菜单
/// 遵循MVVM架构，只负责UI展示
struct ComicReaderMenuBar: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isVisible: Bool
    let geometry: GeometryProxy
    
    // 分享按钮的占位符动作
    let onShareTapped: () -> Void
    
    var body: some View {
        ZStack {
            // 半透明背景遮罩
            if isVisible {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isVisible = false
                        }
                    }
            }
            
            // 菜单栏内容
            VStack {
                // 顶部菜单栏
                if isVisible {
                    topMenuBar
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Spacer()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isVisible)
    }
    
    /// 顶部菜单栏
    private var topMenuBar: some View {
        HStack {
            Spacer()
            
            // 右侧按钮组 - 放在最右侧
            HStack(spacing: 20) {
                // 分享按钮
                shareButton
                
                // 关闭按钮
                closeButton
            }
            .padding(.trailing, 30) // 确保在最右侧
        }
        .padding(.top, 20)
        .padding(.horizontal, 20)
        .background(
            // 渐变背景
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.6),
                    Color.clear
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 100)
        )
    }
    
    /// 分享按钮
    private var shareButton: some View {
        Button(action: onShareTapped) {
            Image(systemName: "square.and.arrow.up")
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.5))
                )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("分享")
        .accessibilityHint("分享当前连环画")
    }
    
    /// 关闭按钮
    private var closeButton: some View {
        Button(action: {
            dismiss()
        }) {
            Image(systemName: "xmark")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.5))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    GeometryReader { geometry in
        ZStack {
            // 模拟背景
            Color.brown.opacity(0.3)
                .ignoresSafeArea()
            
            ComicReaderMenuBar(
                isVisible: .constant(true),
                geometry: geometry,
                onShareTapped: {
                    print("分享按钮被点击")
                }
            )
        }
    }
    .preferredColorScheme(.dark)
}
