import SwiftUI

/// 互动问题页面视图 - 符合MVVM架构，只负责UI展示
struct QuestionsView: View {
    let questions: [String]
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
                // 上方标题区域 - 参考ComicPanelView的结构
                Text("互动问题")
                    .font(.custom("WSQuanXing", size: 20))
                    .foregroundColor(Color(hex: "#855C23"))
                    .fontWeight(.medium)
                    .padding(.horizontal, 20)

                // 下方问题内容区域 - 限制高度避免"完"被推到底部
                VStack(spacing: 16) {
                    ScrollView {
                        TypewriterView(
                            text: questions.enumerated().map { index, question in
                                "\(index + 1). \(question)"
                            }.joined(separator: "\n\n"),
                            typeSpeed: 0.10,
                            showCursor: false
                        )
                        .font(.custom("STKaiti", size: 18))
                        .foregroundColor(Color(hex: "#2F2617"))
                        .lineSpacing(8)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20) // 给ScrollView底部添加一些间距
                    }
                    .frame(maxHeight: 400) // 限制ScrollView的最大高度

                    // 页码
                    Text("· 完 ·")
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
struct QuestionsView_Previews: PreviewProvider {
    static var previews: some View {
        GeometryReader { geometry in
            QuestionsView(
                questions: [
                    "你觉得小明为什么会选择\"阳光\"这个名字给小狗？",
                    "如果你是小明，你会如何处理这只突然出现的流浪狗？",
                    "这个故事告诉我们什么关于友谊和善良的道理？"
                ],
                geometry: geometry,
                pageIndex: 3,
                totalPages: 4
            )
        }
        .previewDevice("iPhone 14")
    }
}
