import SwiftUI

/// 单独的漫画页面视图组件 - 横屏左右布局，符合MVVM架构
struct ComicPanelView: View {
    let panel: ComicPanel
    let geometry: GeometryProxy
    let pageIndex: Int
    let totalPages: Int

    var body: some View {
        ZStack {
            // 背景图片
            Image("背景单色")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            GeometryReader { geometry in
                HStack(spacing: 30) {
                    // 左侧：图片区域
                    VStack {
                        AsyncImageView(imageUrl: panel.imageUrl)
                            .aspectRatio(contentMode: .fit)
                            .overlay(
                                RoundedRectangle(cornerRadius: 0)
                                    .stroke(Color(hex: "#2F2617"), lineWidth: 2)
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(width: geometry.size.width * 0.60)
                    .padding(.leading, 20)

                    // 右侧：文本区域
                    VStack(spacing: 0) {
                        // 文本内容区域 - "目"字上面的"口"
                        VStack {
                            if let narration = panel.narration {
                                Text(narration)
                                    .font(.custom("STKaiti", size: 16))
                                    .foregroundColor(Color(hex: "#2F2617"))
                                    .lineSpacing(6)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                            } else {
                                // 如果没有叙述文本，显示占位符
                                VStack(spacing: 12) {
                                    Image(systemName: "text.bubble")
                                        .font(.system(size: 30))
                                        .foregroundColor(Color(hex: "#2F2617").opacity(0.5))
                                    Text("暂无文本描述")
                                        .font(.custom("STKaiti", size: 16))
                                        .foregroundColor(Color(hex: "#2F2617").opacity(0.5))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 200) // 确保有足够高度
                        .padding(.horizontal, 10)
                        .padding(.top, 20)

                        // 分隔线 - "目"字中间的横线
                        Rectangle()
                            .fill(Color.black)
                            .frame(height: 1)
                            .padding(.horizontal, 10)

                        // 页码区域 - "目"字下面的"口"
                        VStack {
                            Text("· \(pageIndex + 1) ·")
                                .font(.custom("STKaiti", size: 16))
                                .foregroundColor(Color(hex: "#2F2617"))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60) // 固定页码区域高度
                        .padding(.horizontal, 10)
                    }
                    .frame(width: geometry.size.width * 0.30 - 20) // 减去右边距，避免超出屏幕
                    .padding(.trailing, 20)
                    // 添加黑边显示文本活动范围 - "目"字的外轮廓
                    .overlay(
                        Rectangle()
                            .stroke(Color.black, lineWidth: 3)
                    )
                    .background(Color.black.opacity(0.1))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 20)
            }
        }
    }
}

// MARK: - Preview
struct ComicPanelView_Previews: PreviewProvider {
    static var previews: some View {
        GeometryReader { geometry in
            ComicPanelView(
                panel: ComicPanel(
                    panelNumber: 1,
                    imageUrl: "Image1",
                    narration: "在一个阳光明媚的早晨，小明背着书包走在上学的路上。他哼着小曲，心情格外愉快，因为今天是他的生日。"
                ),
                geometry: geometry,
                pageIndex: 0,
                totalPages: 3
            )
        }
        .previewDevice("iPhone 14")
        .previewInterfaceOrientation(.landscapeLeft)
    }
}
