import SwiftUI
import PhotosUI
import UIKit

struct OpenResultsView: View {
    @Environment(\.dismiss) private var dismiss
    let comicResult: ComicResult

    // 检测设备方向 - 暂时不使用，保留以备将来使用
    // private var isLandscape: Bool {
    //     UIDevice.current.orientation.isLandscape ||
    //     UIApplication.shared.connectedScenes
    //         .compactMap { $0 as? UIWindowScene }
    //         .first?.interfaceOrientation.isLandscape == true
    // }

    var body: some View {
        ZStack {
            // 背景图片
            Image("背景单色")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            GeometryReader { geometry in
                // 强制使用竖屏布局
                self.portraitLayout(geometry)

                // 保留横屏布局代码以备将来使用
                // if isLandscape {
                //     // 横屏布局
                //     self.landscapeLayout(geometry)
                // } else {
                //     // 竖屏布局
                //     self.portraitLayout(geometry)
                // }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        // .navigationBarBackButtonHidden(false)
        // .toolbarBackground(Color.clear, for: .navigationBar)
        .onAppear {
            // 强制竖屏显示
            AppDelegate.orientationLock = .portrait
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            }
        }
    }
}

// MARK: - 布局扩展
extension OpenResultsView {
    /// 横屏布局
    @ViewBuilder
    private func landscapeLayout(_ geometry: GeometryProxy) -> some View {
        HStack(spacing: geometry.size.width * 0.04) {
            // 左侧：图片区域
            VStack {
                Spacer()

                if let firstPanel = comicResult.panels.first {
                    AsyncImageView(imageUrl: firstPanel.imageUrl)
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: geometry.size.height * 0.7)
                } else {
                    // 如果没有页面，显示默认封面
                    Image("封面")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: geometry.size.height * 0.7)
                }

                Spacer()
            }
            .frame(width: geometry.size.width * 0.60)
            .padding(.leading, geometry.size.width * 0.03)

            // 右侧：文本和按钮区域
            VStack(spacing: 0) {
                Spacer()

                // 显示连环画标题
                Text(comicResult.title)
                    .font(.custom("WSQuanXing", size: min(geometry.size.width * 0.03, 28)))
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "#855C23"))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)

                Spacer()
                    .frame(maxHeight: geometry.size.height * 0.05)

                // 显示故事摘要作为描述
                Text(comicResult.summary ?? "暂无故事摘要")
                    .font(.custom("STKaiti", size: min(geometry.size.width * 0.02, 18)))
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.18, green: 0.15, blue: 0.09))
                    .opacity(0.6)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)

                Spacer()
                    .frame(maxHeight: geometry.size.height * 0.08)

                NavigationLink {
                    ComicResultView(comicResult: comicResult)
                } label: {
                    ZStack {
                        Image("button1")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(
                                width: min(geometry.size.width * 0.25, 240),
                                height: min(geometry.size.height * 0.08, 45)
                            )

                        Text("翻开画册")
                            .font(.custom("WSQuanXing", size: min(geometry.size.width * 0.025, 24)))
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "#855C23"))
                    }
                }

                Spacer()
            }
            .frame(width: geometry.size.width * 0.30)
            .padding(.trailing, geometry.size.width * 0.03)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, geometry.size.height * 0.03)
    }

    /// 竖屏布局
    @ViewBuilder
    private func portraitLayout(_ geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // 顶部弹性空间 - 响应式
            Spacer()
                .frame(minHeight: geometry.size.height * 0.03, maxHeight: geometry.size.height * 0.08)

            // 图片区域
            if let firstPanel = comicResult.panels.first {
                AsyncImageView(imageUrl: firstPanel.imageUrl)
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: geometry.size.height * 0.35)
                    .padding(.horizontal, geometry.size.width * 0.05)
            } else {
                // 如果没有页面，显示默认封面
                Image("封面")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: geometry.size.height * 0.35)
                    .padding(.horizontal, geometry.size.width * 0.05)
            }

            // 图片和文本之间的弹性间距
            Spacer()
                .frame(
                    minHeight: geometry.size.height * 0.02,
                    maxHeight: geometry.size.height * 0.06
                )

            // 文本区域
            VStack(spacing: geometry.size.height * 0.02) {
                // 显示连环画标题
                Text(comicResult.title)
                    .font(.custom("WSQuanXing", size: min(geometry.size.width * 0.07, 32)))
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "#855C23"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, geometry.size.width * 0.05)

                // 显示故事摘要作为描述
                Text(comicResult.summary ?? "暂无故事摘要")
                    .font(.custom("STKaiti", size: min(geometry.size.width * 0.045, 20)))
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.18, green: 0.15, blue: 0.09))
                    .opacity(0.6)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, geometry.size.width * 0.05)
                    .lineLimit(5)
                    .lineSpacing(geometry.size.height * 0.005)
            }

            // 文本和按钮之间的弹性间距
            Spacer()
                .frame(
                    minHeight: geometry.size.height * 0.03,
                    maxHeight: geometry.size.height * 0.08
                )

            // 按钮区域
            NavigationLink {
                ComicResultView(comicResult: comicResult)
            } label: {
                ZStack {
                    Image("button1")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(
                            width: min(geometry.size.width * 0.65, 280),
                            height: min(geometry.size.height * 0.06, 52)
                        )

                    Text("翻开画册")
                        .font(.custom("WSQuanXing", size: min(geometry.size.width * 0.065, 28)))
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "#855C23"))
                }
            }

            // 底部弹性空间 - 响应式
            Spacer()
                .frame(minHeight: geometry.size.height * 0.04, maxHeight: geometry.size.height * 0.1)
        }
        .padding(.horizontal, geometry.size.width * 0.05)
        .padding(.vertical, geometry.size.height * 0.02)
    }
}
