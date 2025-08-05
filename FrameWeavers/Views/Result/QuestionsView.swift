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

            GeometryReader { geometry in
                // 问题内容区域 - 使用全屏宽度
                VStack(spacing: 0) {
                    // 问题内容区域 - "目"字上面的"口"
                    VStack {
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
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 200) // 确保有足够高度
                    .padding(.horizontal, 40) // 左右边距
                    .padding(.top, 20)

                    // 分隔线 - "目"字中间的横线
                    Rectangle()
                        .fill(Color.black)
                        .frame(height: 1)
                        .padding(.horizontal, 40)

                    // "完"字区域 - "目"字下面的"口"
                    VStack {
                        Text("· 完 ·")
                            .font(.custom("STKaiti", size: 16))
                            .foregroundColor(Color(hex: "#2F2617"))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 60) // 固定完字区域高度
                    .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity) // 使用全屏宽度
                .padding(.horizontal, 20) // 整体左右边距
                // 添加黑边显示文本活动范围 - "目"字的外轮廓
                .overlay(
                    Rectangle()
                        .stroke(Color.black, lineWidth: 3)
                )
                .background(Color.black.opacity(0.1))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 20)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        // .toolbar {
        //     ToolbarItem(placement: .principal) {
        //         Text("互动问题")
        //             .font(.custom("WSQuanXing", size: 20))
        //             .foregroundColor(Color(hex: "#855C23"))
        //             .fontWeight(.medium)
        //     }
        // }
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
        .previewInterfaceOrientation(.landscapeLeft)
    }
}
