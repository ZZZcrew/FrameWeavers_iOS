import SwiftUI

/// 互动问题页面视图 - 符合MVVM架构，只负责UI展示
struct QuestionsView: View {
    let questions: [String]
    let geometry: GeometryProxy
    let pageIndex: Int
    let totalPages: Int

    // 判断是否为横屏
    private var isLandscape: Bool {
        geometry.size.width > geometry.size.height
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: isLandscape ? 15 : 30) {
                Text("互动问题")
                    .font(.custom("STKaiti", size: isLandscape ? 20 : 28))
                    .foregroundColor(Color(hex: "#855C23"))

                ScrollView {
                    VStack(alignment: .leading, spacing: isLandscape ? 12 : 20) {
                        ForEach(questions, id: \.self) { question in
                            HStack(alignment: .top, spacing: 12) {
                                TypewriterView(
                                    text: question,
                                    typeSpeed: 0.10,
                                    showCursor: false
                                )
                                .font(.custom("STKaiti", size: isLandscape ? 14 : 18))
                                .foregroundColor(Color(hex: "#2F2617"))
                            }
                            .padding(isLandscape ? 8 : 16)
                            .background(Color.clear)
                        }
                    }
                    .padding(.horizontal, isLandscape ? 30 : 20)
                }
                .frame(maxHeight: isLandscape ? geometry.size.height * 0.6 : .infinity)
            }
            .frame(maxWidth: geometry.size.width * (isLandscape ? 0.85 : 0.9))
            .frame(maxHeight: isLandscape ? geometry.size.height * 0.8 : .infinity)

            Spacer()

            // 底部页码
            Text("· 完 ·")
                .font(.custom("STKaiti", size: isLandscape ? 14 : 16))
                .foregroundColor(Color(hex: "#2F2617"))
                .padding(8)
                .background(Color.clear)
                .padding(.bottom, isLandscape ? 10 : 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, isLandscape ? 20 : 0)
        .padding(.vertical, isLandscape ? 10 : 0)
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
