import SwiftUI

/// 简化的照片堆叠视图组件 - 纯UI组件，遵循单一职责原则
struct PhotoStackView: View {
    let mainImageName: String
    let stackedImages: [String]
    let namespace: Namespace.ID
    let baseFrames: [String: BaseFrameData] // 基础帧数据映射

    init(mainImageName: String,
         stackedImages: [String],
         namespace: Namespace.ID,
         baseFrames: [String: BaseFrameData] = [:]) {
        self.mainImageName = mainImageName
        self.stackedImages = stackedImages
        self.namespace = namespace
        self.baseFrames = baseFrames
    }

    var body: some View {
        ZStack {
            // 堆叠的背景图片
            ForEach(stackedImages.indices, id: \.self) { index in
                let imageName = stackedImages[index]
                let offset = CGFloat(index) * 3
                let rotation = Double.random(in: -8...8)
                let baseFrame = baseFrames[imageName]

                ZStack {
                    if let baseFrame = baseFrame, let url = baseFrame.thumbnailURL {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(0.5)
                                )
                        }
                    } else if baseFrame == nil {
                        // 只有在没有基础帧数据时才显示本地图片
                        Image(imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        // 有基础帧数据但URL无效时显示错误状态
                        Rectangle()
                            .fill(Color.orange.opacity(0.3))
                            .overlay(
                                Text("URL无效")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            )
                    }
                }
                .frame(width: 300, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .background(
                    RoundedRectangle(cornerRadius: 8).fill(.white)
                )
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                .rotationEffect(.degrees(rotation))
                .offset(x: offset, y: -offset)
                .zIndex(Double(index))
            }

            // 主图卡片
            ZStack {
                if !mainImageName.isEmpty {
                    let mainBaseFrame = baseFrames[mainImageName]
                    if let baseFrame = mainBaseFrame, let url = baseFrame.thumbnailURL {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(0.5)
                                )
                        }
                        .matchedGeometryEffect(id: mainImageName, in: namespace)
                    } else if mainBaseFrame == nil {
                        // 只有在没有基础帧数据时才显示本地图片
                        Image(mainImageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .matchedGeometryEffect(id: mainImageName, in: namespace)
                    } else {
                        // 有基础帧数据但URL无效时显示错误状态
                        Rectangle()
                            .fill(Color.orange.opacity(0.3))
                            .overlay(
                                Text("URL无效")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            )
                            .matchedGeometryEffect(id: mainImageName, in: namespace)
                    }
                }
            }
            .frame(width: 300, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .background(
                RoundedRectangle(cornerRadius: 8).fill(.white)
            )
            .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
            .rotationEffect(.degrees(1))
            .zIndex(Double(stackedImages.count + 1))

            // 胶带
            Image("胶带")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .opacity(0.6)  // 60%不透明度
                .frame(width: 200, height: 50)
                .offset(y: -100)
                .zIndex(Double(stackedImages.count + 2))
        }
        .frame(height: 250)
    }
}

// MARK: - Preview
struct PhotoStackView_Previews: PreviewProvider {
    @Namespace static var namespace

    static var previews: some View {
        VStack(spacing: 40) {
            // 预览1：基本状态
            PhotoStackView(
                mainImageName: "Image1",
                stackedImages: [],
                namespace: namespace,
                baseFrames: [:]
            )
            .previewDisplayName("基本状态")

            // 预览2：有堆叠图片
            PhotoStackView(
                mainImageName: "Image2",
                stackedImages: ["Image1", "Image3"],
                namespace: namespace,
                baseFrames: [:]
            )
            .previewDisplayName("有堆叠图片")
        }
        .padding()
        .background(Color(red: 0.91, green: 0.88, blue: 0.83))
        .previewLayout(.sizeThatFits)
    }
}