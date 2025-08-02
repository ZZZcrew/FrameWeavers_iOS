import SwiftUI
import PhotosUI
import UIKit

struct OpenResultsView: View {
    @Environment(\.dismiss) private var dismiss
    let comicResult: ComicResult
    
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
                        if let firstPanel = comicResult.panels.first {
                            AsyncImageView(imageUrl: firstPanel.imageUrl)
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .shadow(radius: 10)
                        } else {
                            // 如果没有页面，显示默认封面
                            Image("封面")
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .shadow(radius: 10)
                        }
                    }
                    .frame(width: geometry.size.width * 0.45)
                    .padding(.leading, 20)

                    // 右侧：文本和按钮区域
                    VStack(spacing: 25) {
                        // 显示连环画标题
                        Text(comicResult.title)
                            .font(.custom("WSQuanXing", size: 26))
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "#855C23"))
                            .multilineTextAlignment(.center)
                            .lineLimit(3)

                        // 显示第一页的旁白作为描述
                        if let firstPanel = comicResult.panels.first, let narration = firstPanel.narration {
                            Text(narration)
                                .font(.custom("STKaiti", size: 16))
                                .fontWeight(.bold)
                                .foregroundColor(Color(red: 0.18, green: 0.15, blue: 0.09))
                                .opacity(0.6)
                                .multilineTextAlignment(.center)
                                .lineLimit(5)
                        }

                        NavigationLink {
                            ComicResultView(comicResult: comicResult)
                        } label: {
                            ZStack {
                                Image("button1")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 250, height: 44)

                                Text("翻开画册")
                                    .font(.custom("WSQuanXing", size: 24))
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(hex: "#855C23"))
                            }
                        }
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
        // .navigationBarBackButtonHidden(false)
        // .toolbarBackground(Color.clear, for: .navigationBar)
        .onAppear {
            // 强制横屏显示
            AppDelegate.orientationLock = .landscape
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
            }
        }
    }
}
