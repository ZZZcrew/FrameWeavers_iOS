import SwiftUI

/// 漫画页面视图组件 - 纯UI组件，遵循单一职责原则
/// 支持横竖屏布局，负责展示单个漫画页面
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

    // MARK: - 竖屏布局
    private var portraitLayout: some View {
        VStack(spacing: 0) {
            // 上方图片区域 - 宽度占满，高度根据图片比例自适应，但不超过70%屏幕高度
            AsyncImageView(imageUrl: panel.imageUrl)
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .frame(maxHeight: geometry.size.height * 0.7) // 最大不超过70%高度
                .background(Color.clear)
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.top, 20)

            // 下方文本区域 - 占据剩余空间，最小30%高度
            VStack(spacing: 0) {
                textContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // 底部页码
                PageIndicatorView(
                    currentPage: pageIndex + 1,
                    totalPages: totalPages,
                    isLandscape: isLandscape
                )
            }
            .frame(minHeight: geometry.size.height * 0.3) // 最小30%高度保证文本可读
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 横屏布局
    private var landscapeLayout: some View {
        HStack(spacing: 0) {
            // 左侧图片区域 - 高度占满，宽度根据图片比例自适应，但不超过60%屏幕宽度
            AsyncImageView(imageUrl: panel.imageUrl)
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: .infinity)
                .frame(maxWidth: geometry.size.width * 0.6) // 最大不超过60%宽度
                .background(Color.clear)
                .cornerRadius(8)
                .padding(.leading, 20)
                .padding(.vertical, 20)

            // 右侧文本区域 - 占据剩余空间，最小35%宽度
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
                            EmptyTextPlaceholderView()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color.clear)
                .cornerRadius(8)

                // 页码
                PageIndicatorView(
                    currentPage: pageIndex + 1,
                    totalPages: totalPages,
                    isLandscape: isLandscape
                )
            }
            .frame(minWidth: geometry.size.width * 0.35) // 最小35%宽度保证文本可读
            .frame(maxHeight: .infinity)
            .padding(.trailing, 20)
            .padding(.vertical, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 文本内容组件
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
                EmptyTextPlaceholderView()
                    .background(Color.clear)
                    .cornerRadius(12)
            }
        }
    }
}

// MARK: - 空文本占位符组件
struct EmptyTextPlaceholderView: View {
    var body: some View {
        VStack {
            Image(systemName: "text.bubble")
                .font(.largeTitle)
                .foregroundColor(.gray.opacity(0.5))
            Text("暂无文本描述")
                .foregroundColor(.gray.opacity(0.5))
                .font(.body)
        }
    }
}

// MARK: - 页码指示器组件
struct PageIndicatorView: View {
    let currentPage: Int
    let totalPages: Int
    let isLandscape: Bool
    
    var body: some View {
        Text("· \(currentPage) ·")
            .font(.custom("STKaiti", size: isLandscape ? 14 : 16))
            .foregroundColor(Color(hex: "#2F2617"))
            .padding(8)
            .background(Color.clear)
            .padding(.bottom, isLandscape ? 10 : 20)
    }
}

// MARK: - 预览
struct ComicPanelView_Previews: PreviewProvider {
    static var previews: some View {
        GeometryReader { geometry in
            ComicPanelView(
                panel: ComicPanel(
                    panelNumber: 1,
                    imageUrl: "Image1",
                    narration: "这是一个测试的漫画页面，用于展示组件的布局效果。"
                ),
                geometry: geometry,
                pageIndex: 0,
                totalPages: 3
            )
        }
        .previewDisplayName("漫画页面预览")
    }
}
