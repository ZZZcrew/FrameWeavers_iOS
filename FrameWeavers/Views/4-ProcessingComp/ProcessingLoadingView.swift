import SwiftUI

/// 处理加载视图组件，统一的进度条显示
struct ProcessingLoadingView: View {
    let progress: Double
    let status: UploadStatus
    
    var body: some View {
        VStack(spacing: 15) {
            Text(statusText)
                .font(.custom("STKaiti", size: 16))
                .foregroundColor(Color(hex: "#2F2617"))

            ZStack(alignment: .leading) {
                Capsule().fill(Color.black.opacity(0.1))
                Capsule()
                    .fill(Color(hex: "#855C23"))
                    .frame(width: 200 * CGFloat(progress))
            }
            .frame(width: 200, height: 6)

            Text("\(Int(progress * 100))%")
                .font(.custom("STKaiti", size: 14))
                .foregroundColor(Color(hex: "#855C24"))
        }
    }
    
    /// 根据状态获取对应的文本
    private var statusText: String {
        switch status {
        case .pending: return "准备中..."
        case .uploading: return "上传中..."
        case .processing: return "正在生成你的回忆画册..."
        case .completed: return "处理完成！"
        case .failed: return "处理失败"
        }
    }
}