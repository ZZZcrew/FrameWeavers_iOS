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
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(width: geometry.size.width * 0.60)
                    .padding(.leading, 20)

                    // 右侧：文本区域
                    VStack(spacing: 20) {
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

                        // 页码
                        Text("· \(pageIndex + 1) ·")
                            .font(.custom("STKaiti", size: 15))
                            .foregroundColor(Color(hex: "#2F2617"))
                            .padding(6)
                    }
                    .frame(width: geometry.size.width * 0.30)
                    .padding(.trailing, 20)
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
