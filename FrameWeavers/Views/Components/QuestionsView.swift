import SwiftUI

/// 互动问题页面视图组件 - 纯UI组件，遵循单一职责原则
/// 负责展示互动问题列表，支持横竖屏布局
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
                // 标题
                QuestionsHeaderView(isLandscape: isLandscape)
                
                // 问题列表
                QuestionsListView(
                    questions: questions,
                    geometry: geometry,
                    isLandscape: isLandscape
                )
            }
            .frame(maxWidth: geometry.size.width * (isLandscape ? 0.85 : 0.9))
            .frame(maxHeight: isLandscape ? geometry.size.height * 0.8 : .infinity)

            Spacer()

            // 底部完成标识
            QuestionsFooterView(isLandscape: isLandscape)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, isLandscape ? 20 : 0)
        .padding(.vertical, isLandscape ? 10 : 0)
    }
}

// MARK: - 问题页面标题组件
struct QuestionsHeaderView: View {
    let isLandscape: Bool
    
    var body: some View {
        Text("互动问题")
            .font(.custom("STKaiti", size: isLandscape ? 20 : 28))
            .foregroundColor(Color(hex: "#855C23"))
    }
}

// MARK: - 问题列表组件
struct QuestionsListView: View {
    let questions: [String]
    let geometry: GeometryProxy
    let isLandscape: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: isLandscape ? 12 : 20) {
                ForEach(questions, id: \.self) { question in
                    QuestionItemView(
                        question: question,
                        isLandscape: isLandscape
                    )
                }
            }
            .padding(.horizontal, isLandscape ? 30 : 20)
        }
        .frame(maxHeight: isLandscape ? geometry.size.height * 0.6 : .infinity)
    }
}

// MARK: - 单个问题项组件
struct QuestionItemView: View {
    let question: String
    let isLandscape: Bool
    
    var body: some View {
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

// MARK: - 问题页面底部组件
struct QuestionsFooterView: View {
    let isLandscape: Bool
    
    var body: some View {
        Text("· 完 ·")
            .font(.custom("STKaiti", size: isLandscape ? 14 : 16))
            .foregroundColor(Color(hex: "#2F2617"))
            .padding(8)
            .background(Color.clear)
            .padding(.bottom, isLandscape ? 10 : 20)
    }
}

// MARK: - 预览
struct QuestionsView_Previews: PreviewProvider {
    static var previews: some View {
        GeometryReader { geometry in
            QuestionsView(
                questions: [
                    "你觉得这个故事最有趣的部分是什么？",
                    "如果你是主角，你会做出不同的选择吗？",
                    "这个故事给你带来了什么启发？"
                ],
                geometry: geometry,
                pageIndex: 3,
                totalPages: 4
            )
        }
        .previewDisplayName("问题页面预览")
    }
}
