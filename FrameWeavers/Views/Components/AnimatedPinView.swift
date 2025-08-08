import SwiftUI

/// 带动画效果的图钉组件
struct AnimatedPinView: View {
    let currentIndex: Int
    let quadrantSize: CGFloat
    let isAnimating: Bool

    init(currentIndex: Int, quadrantSize: CGFloat, isAnimating: Bool) {
        self.currentIndex = currentIndex
        self.quadrantSize = quadrantSize
        self.isAnimating = isAnimating

        let positions = AnimatedPinView.computePinPositions(for: quadrantSize)
        let initialPoint = CGPoint(x: positions[min(max(0, currentIndex), positions.count - 1)].x,
                                   y: positions[min(max(0, currentIndex), positions.count - 1)].y)
        self._animatedPosition = State(initialValue: initialPoint)
        self._currentPositionIndex = State(initialValue: min(max(0, currentIndex), positions.count - 1))
    }

    @State private var pinOffset: CGFloat = 0
    @State private var pinRotation: Double = 0
    @State private var pinScale: CGFloat = 1.0
    @State private var showShadow: Bool = true
    @State private var hasAppeared: Bool = false  // 控制是否已经出现过

    // 动画状态
    @State private var animationPhase: AnimationPhase = .idle
    @State private var currentPositionIndex: Int = 1  // 当前图钉实际显示的位置索引
    @State private var animatedPosition: CGPoint = CGPoint.zero  // 用于平滑位置过渡的动画位置

    enum AnimationPhase {
        case idle           // 静止状态
        case pullOut        // 拔出阶段
        case moving         // 移动阶段
        case insertDown     // 插入阶段
    }
    
    var body: some View {
        ZStack {
            // 主图钉
            Image("图钉")
                .resizable()
                .scaledToFit()
                .frame(width: quadrantSize * 0.14, height: quadrantSize * 0.14)
                .scaleEffect(pinScale)
                .rotationEffect(.degrees(pinRotation))
                .offset(y: pinOffset)
                .position(x: animatedPosition.x, y: animatedPosition.y)
                .shadow(
                    color: showShadow ? Color.black.opacity(0.3) : Color.clear,
                    radius: showShadow ? 3 : 0,
                    x: showShadow ? 2 : 0,
                    y: showShadow ? 4 : 0
                )
        }
        .onChange(of: currentIndex) { oldValue, newValue in
            if oldValue != newValue && hasAppeared && isAnimating {
                startPinAnimation(from: oldValue, to: newValue)
            }
        }
        .onAppear {
            // 首次进入不进行任何动画，保持静止
            hasAppeared = true
        }
    }
    
    /// 计算图钉的响应式位置
    private var pinPositions: [(x: CGFloat, y: CGFloat)] {
        Self.computePinPositions(for: quadrantSize)
    }

    private static func computePinPositions(for size: CGFloat) -> [(x: CGFloat, y: CGFloat)] {
        let offsetX = size * 0.45  // 相对于中心的X偏移
        let offsetY = size * 0.1   // 相对于顶部的Y偏移
        let centerX = size * 0.5
        let centerY = size * 0.5

        return [
            (x: centerX - offsetX + size * 0.42, y: centerY - offsetY - size * 0.28),
            (x: centerX + offsetX - size * 0.06, y: centerY - offsetY - size * 0.28),
            (x: centerX - offsetX + size * 0.42, y: centerY + offsetY - size * 0.07),
            (x: centerX + offsetX - size * 0.06, y: centerY + offsetY - size * 0.07)
        ]
    }
    
    /// 开始图钉切换动画 - 优化性能版本
    private func startPinAnimation(from oldIndex: Int, to newIndex: Int) {
        guard oldIndex != newIndex else { return }

        // 使用单个动画序列，避免多个DispatchQueue调用
        animationPhase = .pullOut

        // 第一阶段：拔出动画
        withAnimation(.easeOut(duration: 0.15)) {
            pinOffset = -15  // 向上拔出
            pinRotation = Double.random(in: -8...8)  // 轻微摇摆
            pinScale = 1.08   // 稍微放大
        }

        withAnimation(.easeOut(duration: 0.1).delay(0.15)) {
            pinOffset = -30  // 继续向上拔出
            pinRotation = Double.random(in: -15...15)  // 更大摇摆
            pinScale = 1.15
            showShadow = false  // 隐藏阴影
        }

        // 使用Task替代DispatchQueue，性能更好
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3秒

            // 第二阶段：移动动画
            animationPhase = .moving
            let newPosition = CGPoint(x: pinPositions[newIndex].x, y: pinPositions[newIndex].y)

            // 同时进行位置移动和高度变化的动画
            withAnimation(.easeInOut(duration: 0.8)) {  // 缩短到0.8秒，让移动更流畅
                animatedPosition = newPosition  // 平滑移动到新位置
                pinOffset = -40  // 飞行到最高点
                pinRotation = Double.random(in: -25...25)  // 飞行中的旋转
                pinScale = 1.2  // 在空中时稍大
            }

            // 更新内部位置索引
            currentPositionIndex = newIndex

            try? await Task.sleep(nanoseconds: 800_000_000) // 0.8秒

            // 第三阶段：插入动画
            animationPhase = .insertDown

            withAnimation(.easeIn(duration: 0.15)) {
                pinOffset = 2    // 稍微插入过深
                pinRotation = 0   // 恢复正常角度
                pinScale = 0.95  // 压缩效果
                showShadow = true  // 显示阴影
            }

            // 弹回效果
            withAnimation(.interpolatingSpring(stiffness: 200, damping: 15)) {
                pinOffset = 0
                pinScale = 1.0
                pinRotation = 0
            }

            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3秒

            // 最终稳定
            withAnimation(.spring(response: 0.15, dampingFraction: 0.8)) {
                pinScale = 1.0
            }

            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
            animationPhase = .idle
        }
    }
    
    /// 初始插入动画 - 优化性能版本
    private func startInsertAnimation() {
        // 初始状态
        pinOffset = -60
        pinScale = 1.3
        pinRotation = Double.random(in: -20...20)
        showShadow = false

        // 使用Task替代多个DispatchQueue调用
        Task { @MainActor in
            // 快速下降
            withAnimation(.easeOut(duration: 0.3)) {
                pinOffset = -10
                pinScale = 1.15
                pinRotation = Double.random(in: -10...10)
            }

            try? await Task.sleep(nanoseconds: 400_000_000) // 0.4秒

            // 插入冲击
            withAnimation(.easeIn(duration: 0.08)) {
                pinOffset = 5
                pinScale = 0.85
                pinRotation = 0
                showShadow = true
            }

            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒

            // 弹回到正确位置
            withAnimation(.interpolatingSpring(stiffness: 180, damping: 12)) {
                pinOffset = 0
                pinScale = 1.0
            }

            try? await Task.sleep(nanoseconds: 400_000_000) // 0.4秒

            // 最终稳定
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                pinScale = 1.0
            }
        }
    }
}

/// 图钉动画预览
struct AnimatedPinView_Previews: PreviewProvider {
    @State static var currentIndex = 1
    
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.2)
            
            VStack {
                AnimatedPinView(
                    currentIndex: currentIndex,
                    quadrantSize: 300,
                    isAnimating: false
                )
                .frame(width: 300, height: 300)
                
                HStack {
                    ForEach(0..<4) { index in
                        Button("位置 \(index)") {
                            currentIndex = index
                        }
                        .padding()
                        .background(currentIndex == index ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
        }
    }
}
