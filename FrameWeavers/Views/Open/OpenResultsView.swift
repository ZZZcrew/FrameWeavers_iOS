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

                // 显示故事摘要作为描述
                Text(comicResult.summary ?? "暂无故事摘要")
                    .font(.custom("STKaiti", size: 15))
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.18, green: 0.15, blue: 0.09))
                    .opacity(0.6)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)

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
        VStack(spacing: 0) {
            // 顶部弹性空间
            Spacer()
                .frame(minHeight: 20)

            // 图片区域
            if let firstPanel = comicResult.panels.first {
                AsyncImageView(imageUrl: firstPanel.imageUrl)
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: geometry.size.height * 0.35)
                    .shadow(radius: 10)
                    .padding(.horizontal, 20)
            } else {
                // 如果没有页面，显示默认封面
                Image("封面")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: geometry.size.height * 0.35)
                    .shadow(radius: 10)
                    .padding(.horizontal, 20)
            }

            // 图片和文本之间的间距
            Spacer()
                .frame(height: 30)

            // 文本区域
            VStack(spacing: 20) {
                // 显示连环画标题
                Text(comicResult.title)
                    .font(.custom("WSQuanXing", size: 26))
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "#855C23"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                // 显示故事摘要作为描述
                Text(comicResult.summary ?? "暂无故事摘要")
                    .font(.custom("STKaiti", size: 17))
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.18, green: 0.15, blue: 0.09))
                    .opacity(0.6)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .lineLimit(5)
                    .lineSpacing(4)
            }

            // 文本和按钮之间的间距
            Spacer()
                .frame(height: 40)

            // 按钮区域
            NavigationLink {
                ComicResultView(comicResult: comicResult)
            } label: {
                ZStack {
                    Image("button1")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 260, height: 48)

                    Text("翻开画册")
                        .font(.custom("WSQuanXing", size: 26))
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "#855C23"))
                }
            }

            // 底部弹性空间
            Spacer()
                .frame(minHeight: 40)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
    }
}
