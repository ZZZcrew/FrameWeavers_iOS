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
                HStack(spacing: 30) {
                    // 左侧：装饰区域
                    VStack(spacing: 25) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color(hex: "#855C23").opacity(0.6))

                        Text("互动思考")
                            .font(.custom("WSQuanXing", size: 24))
                            .foregroundColor(Color(hex: "#855C23"))
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                    }
                    .frame(width: geometry.size.width * 0.45)
                    .padding(.leading, 20)

                    // 右侧：问题内容区域
                    VStack(spacing: 25) {
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

                        // 页码
                        Text("· 完 ·")
                            .font(.custom("STKaiti", size: 16))
                            .foregroundColor(Color(hex: "#2F2617"))
                            .padding(8)
                    }
                    .frame(width: geometry.size.width * 0.45)
                    .padding(.trailing, 20)
                }
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
