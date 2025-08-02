import SwiftUI

/// 单独的漫画页面视图组件 - 简洁的上下布局，符合MVVM架构
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

            VStack(spacing: 40) {
                // 上方图片区域
                AsyncImageView(imageUrl: panel.imageUrl)
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 300)
                    // .shadow(radius: 10)
                    .padding(.horizontal, 20)

                // 下方文本区域
                VStack(spacing: 16) {
                    if let narration = panel.narration {
                        Text(narration)
                            .font(.custom("STKaiti", size: 16))
                            .foregroundColor(Color(hex: "#2F2617"))
                            .lineSpacing(8)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    } else {
                        // 如果没有叙述文本，显示占位符
                        VStack {
                            Image(systemName: "text.bubble")
                                .font(.largeTitle)
                                .foregroundColor(Color(hex: "#2F2617").opacity(0.5))
                            Text("暂无文本描述")
                                .font(.custom("STKaiti", size: 16))
                                .foregroundColor(Color(hex: "#2F2617").opacity(0.5))
                        }
                    }

                    // 页码
                    Text("· \(pageIndex + 1) ·")
                        .font(.custom("STKaiti", size: 16))
                        .foregroundColor(Color(hex: "#2F2617"))
                        .padding(8)
                }
            }
            .padding()
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
    }
}
