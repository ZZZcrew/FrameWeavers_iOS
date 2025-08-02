import SwiftUI

/// 带动画效果的图钉组件
struct AnimatedPinView: View {
    let currentIndex: Int
    let quadrantSize: CGFloat
    let isAnimating: Bool
    
    @State private var pinOffset: CGFloat = 0
    @State private var pinRotation: Double = 0
    @State private var pinScale: CGFloat = 1.0
    @State private var showShadow: Bool = true

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
                .frame(width: quadrantSize * 0.15, height: quadrantSize * 0.15)
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
            if oldValue != newValue {
                startPinAnimation(from: oldValue, to: newValue)
            }
        }
        .onAppear {
            // 初始化位置和插入动画
            currentPositionIndex = currentIndex
            animatedPosition = CGPoint(x: pinPositions[currentIndex].x, y: pinPositions[currentIndex].y)
            startInsertAnimation()
        }
    }
    
    /// 计算图钉的响应式位置
    private var pinPositions: [(x: CGFloat, y: CGFloat)] {
        let offsetX = quadrantSize * 0.45  // 相对于中心的X偏移
        let offsetY = quadrantSize * 0.1   // 相对于顶部的Y偏移
        let centerX = quadrantSize * 0.5
        let centerY = quadrantSize * 0.5

        return [
            // 往下移动：增大Y值或减小负Y偏移
            // 往上移动：减小Y值或增大负Y偏移
            // 往左移动：减小X值
            // 往右移动：增大X值

            // 左上象限 - 往下走一点点：减小 -size * 0.35 中的 0.35
            (x: centerX - offsetX + quadrantSize * 0.43, y: centerY - offsetY - quadrantSize * 0.3),

            // 右上象限 - 往下、往左走一点点：减小 offsetX，减小 -size * 0.35 中的 0.35
            (x: centerX + offsetX - quadrantSize * 0.05, y: centerY - offsetY - quadrantSize * 0.3),

            // 左下象限 - 往下走多一点点：增大 size * 0.2 中的 0.2
            (x: centerX - offsetX + quadrantSize * 0.43, y: centerY + offsetY - quadrantSize * 0.08),

            // 右下象限 - 往上、往左走一点点：减小 offsetX，减小 size * 0.2 中的 0.2
            (x: centerX + offsetX - quadrantSize * 0.05, y: centerY + offsetY - quadrantSize * 0.08)
        ]
    }
    
    /// 开始图钉切换动画 - 正确的顺序：拔出 → 移动 → 插入
    private func startPinAnimation(from oldIndex: Int, to newIndex: Int) {
        guard oldIndex != newIndex else { return }

        // 第一阶段：拔出动画 - 从当前位置拔出图钉
        animationPhase = .pullOut

        withAnimation(.easeIn(duration: 0.15)) {
            pinOffset = -12  // 向上拔出
            pinRotation = Double.random(in: -5...5)  // 轻微摇摆
            pinScale = 1.05   // 稍微放大
        }

        withAnimation(.easeOut(duration: 0.1).delay(0.15)) {
            pinOffset = -25  // 继续向上拔出
            pinRotation = Double.random(in: -10...10)  // 更大摇摆
            pinScale = 1.1
            showShadow = false  // 隐藏阴影
        }

        // 第二阶段：移动到新位置 - 在空中平滑飞行到新位置
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            animationPhase = .moving

            let newPosition = CGPoint(x: pinPositions[newIndex].x, y: pinPositions[newIndex].y)

            // 同时进行位置移动和高度变化的动画
            withAnimation(.easeInOut(duration: 1.2)) {  // 增加到1.2秒，让移动更慢更明显
                animatedPosition = newPosition  // 平滑移动到新位置
                pinOffset = -35  // 飞行到最高点
                pinRotation = Double.random(in: -20...20)  // 飞行中的旋转
                pinScale = 1.15  // 在空中时稍大
            }

            // 更新内部位置索引
            currentPositionIndex = newIndex
        }

        // 第三阶段：直接插入新位置 - 飞行完成后立即插入
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {  // 调整时间点：0.3 + 1.2 = 1.5
            animationPhase = .insertDown

            withAnimation(.easeIn(duration: 0.15)) {
                pinOffset = 2    // 稍微插入过深
                pinRotation = 0   // 恢复正常角度
                pinScale = 0.95  // 压缩效果
                showShadow = true  // 显示阴影
            }

            // 弹回效果 - 模拟插入后的反弹
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0).delay(0.15)) {
                pinOffset = 0    // 回到正确位置
                pinScale = 1.0   // 恢复原大小
            }

            // 轻微的后续震动
            withAnimation(.spring(response: 0.15, dampingFraction: 0.5, blendDuration: 0).delay(0.3)) {
                pinScale = 0.98
            }

            withAnimation(.spring(response: 0.15, dampingFraction: 0.8, blendDuration: 0).delay(0.4)) {
                pinScale = 1.0
            }
        }

        // 重置状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {  // 调整总时间：1.5 + 0.7 = 2.2
            animationPhase = .idle
        }
    }
    
    /// 初始插入动画 - 模拟第一次插入图钉
    private func startInsertAnimation() {
        // 初始状态：图钉从很高的地方落下
        pinOffset = -50
        pinScale = 1.3
        pinRotation = Double.random(in: -15...15)
        showShadow = false

        // 延迟一点开始动画，让界面先渲染
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // 第一阶段：快速下降
            withAnimation(.easeIn(duration: 0.4)) {
                pinOffset = -5
                pinScale = 1.1
                pinRotation = Double.random(in: -5...5)
            }

            // 第二阶段：插入冲击
            withAnimation(.easeIn(duration: 0.1).delay(0.4)) {
                pinOffset = 3  // 插入过深
                pinScale = 0.9  // 压缩
                pinRotation = 0
                showShadow = true
            }

            // 第三阶段：弹回到正确位置
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0).delay(0.5)) {
                pinOffset = 0
                pinScale = 1.0
            }

            // 第四阶段：轻微震动效果
            withAnimation(.spring(response: 0.2, dampingFraction: 0.4, blendDuration: 0).delay(0.7)) {
                pinScale = 0.95
            }

            withAnimation(.spring(response: 0.2, dampingFraction: 0.8, blendDuration: 0).delay(0.8)) {
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
