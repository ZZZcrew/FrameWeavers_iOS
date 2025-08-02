import SwiftUI
import PhotosUI
import UIKit

struct OpenResultsView: View {
    @Environment(\.dismiss) private var dismiss
    let comicResult: ComicResult

    // 检测设备方向
    private var isLandscape: Bool {
        UIDevice.current.orientation.isLandscape ||
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.interfaceOrientation.isLandscape == true
    }

    var body: some View {
        ZStack {
            // 背景图片
            Image("背景单色")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            GeometryReader { geometry in
                if isLandscape {
                    // 横屏布局
                    self.landscapeLayout(geometry)
                } else {
                    // 竖屏布局
                    self.portraitLayout(geometry)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        // .navigationBarBackButtonHidden(false)
        // .toolbarBackground(Color.clear, for: .navigationBar)
        .onAppear {
            // 支持所有方向
            AppDelegate.orientationLock = .all
        }
    }
}

// MARK: - 布局扩展
extension OpenResultsView {
    /// 横屏布局
    @ViewBuilder
    private func landscapeLayout(_ geometry: GeometryProxy) -> some View {
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
            .frame(width: geometry.size.width * 0.60)
            .padding(.leading, 20)

            // 右侧：文本和按钮区域
            VStack(spacing: 20) {
                // 显示连环画标题
                Text(comicResult.title)
                    .font(.custom("WSQuanXing", size: 24))
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "#855C23"))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)

                // 显示第一页的旁白作为描述
                if let firstPanel = comicResult.panels.first, let narration = firstPanel.narration {
                    Text(narration)
                        .font(.custom("STKaiti", size: 15))
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.18, green: 0.15, blue: 0.09))
                        .opacity(0.6)
                        .multilineTextAlignment(.center)
                        .lineLimit(4)
                }

                NavigationLink {
                    ComicResultView(comicResult: comicResult)
                } label: {
                    ZStack {
                        Image("button1")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 220, height: 40)

                        Text("翻开画册")
                            .font(.custom("WSQuanXing", size: 22))
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "#855C23"))
                    }
                }
            }
            .frame(width: geometry.size.width * 0.30)
            .padding(.trailing, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 20)
    }

    /// 竖屏布局
    @ViewBuilder
    private func portraitLayout(_ geometry: GeometryProxy) -> some View {
        VStack(spacing: 40) {
            // 上方图片区域
            if let firstPanel = comicResult.panels.first {
                AsyncImageView(imageUrl: firstPanel.imageUrl)
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 300)
                    .shadow(radius: 10)
                    .padding(.horizontal, 20)
            } else {
                // 如果没有页面，显示默认封面
                Image("封面")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .shadow(radius: 10)
                    .padding(.horizontal, 20)
            }

            VStack(spacing: 16) {
                // 显示连环画标题
                Text(comicResult.title)
                    .font(.custom("WSQuanXing", size: 24))
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "#855C23"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                // 显示第一页的旁白作为描述
                if let firstPanel = comicResult.panels.first, let narration = firstPanel.narration {
                    Text(narration)
                        .font(.custom("STKaiti", size: 16))
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.18, green: 0.15, blue: 0.09))
                        .opacity(0.6)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .lineLimit(4)
                }
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
        .padding()
    }
}
