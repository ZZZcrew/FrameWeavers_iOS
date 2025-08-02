import SwiftUI

/// 单独的漫画页面视图组件 - 支持横竖屏布局，符合MVVM架构
struct ComicPanelView: View {
    let panel: ComicPanel
    let geometry: GeometryProxy
    let pageIndex: Int
    let totalPages: Int

    // 判断是否为横屏
    private var isLandscape: Bool {
        geometry.size.width > geometry.size.height
    }

    var body: some View {
        if isLandscape {
            // 横屏布局：图片在左，文本在右
            landscapeLayout
        } else {
            // 竖屏布局：图片在上，文本在下
            portraitLayout
        }
    }

    // 竖屏布局
    private var portraitLayout: some View {
        VStack(spacing: 0) {
            // 上方图片区域 - 占据50%高度
            VStack {
                AsyncImageView(imageUrl: panel.imageUrl)
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.clear)
                    .cornerRadius(12)
                    .padding(20)
            }
            .frame(height: geometry.size.height * 0.5)

            // 下方文本区域 - 占据50%高度
            VStack(spacing: 0) {
                textContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // 底部页码
                Text("· \(pageIndex + 1) ·")
                    .font(.custom("STKaiti", size: 16))
                    .foregroundColor(Color(hex: "#2F2617"))
                    .padding(8)
                    .background(Color.clear)
                    .padding(.bottom, 20)
            }
            .frame(height: geometry.size.height * 0.5)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // 横屏布局
    private var landscapeLayout: some View {
        HStack(spacing: 10) {
            // 左侧图片区域 - 占据45%宽度，确保在安全区域内
            VStack {
                AsyncImageView(imageUrl: panel.imageUrl)
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.clear)
                    .cornerRadius(8)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 20)
            }
            .frame(width: geometry.size.width * 0.45)
            .frame(maxHeight: geometry.size.height * 0.8) // 限制高度，留出安全区域

            // 右侧文本区域 - 占据45%宽度
            VStack(spacing: 0) {
                // 文本内容区域
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        if let narration = panel.narration {
                            Text(narration)
                                .font(.custom("STKaiti", size: 14))
                                .foregroundColor(Color(hex: "#2F2617"))
                                .lineSpacing(6)
                                .multilineTextAlignment(.leading)
                        } else {
                            VStack {
                                Image(systemName: "text.bubble")
                                    .font(.title2)
                                    .foregroundColor(.gray.opacity(0.5))
                                Text("暂无文本描述")
                                    .foregroundColor(.gray.opacity(0.5))
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color.clear)
                .cornerRadius(8)

                // 页码
                Text("· \(pageIndex + 1) ·")
                    .font(.custom("STKaiti", size: 14))
                    .foregroundColor(Color(hex: "#2F2617"))
                    .padding(.vertical, 8)
            }
            .frame(width: geometry.size.width * 0.45)
            .frame(maxHeight: geometry.size.height * 0.8) // 限制高度
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    // 文本内容组件
    private var textContent: some View {
        Group {
            if let narration = panel.narration {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(narration)
                            .font(.custom("STKaiti", size: 16))
                            .foregroundColor(Color(hex: "#2F2617"))
                            .lineSpacing(8)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color.clear)
                .cornerRadius(12)
            } else {
                // 如果没有叙述文本，显示占位符
                VStack {
                    Image(systemName: "text.bubble")
                        .font(.largeTitle)
                        .foregroundColor(.gray.opacity(0.5))
                    Text("暂无文本描述")
                        .foregroundColor(.gray.opacity(0.5))
                        .font(.body)
                }
                .background(Color.clear)
                .cornerRadius(12)
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
    }
}
