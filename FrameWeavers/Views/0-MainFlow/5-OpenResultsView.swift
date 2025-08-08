import SwiftUI
import PhotosUI
import UIKit

struct OpenResultsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    let comicResult: ComicResult

    var body: some View {
        ZStack {
            // 背景图片
            Image("背景单色")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            if isLandscape {
                landscapeLayout
            } else {
                portraitLayout
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // 允许所有方向显示，支持横竖屏切换
            AppDelegate.orientationLock = .all
        }
    }
}

// MARK: - 布局扩展
extension OpenResultsView {
    /// 横屏布局
    @ViewBuilder
    private var landscapeLayout: some View {
        HStack(spacing: landscapeSpacing) {
            // 左侧：图片区域
            VStack {
                Spacer()

                if let firstPanel = comicResult.panels.first {
                    ZStack {
                        AsyncImageView(imageUrl: firstPanel.imageUrl)
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: landscapeImageHeight)
                        
                        // 图片上的覆盖标题（位于图片底部）
                        VStack {
                            Spacer()

                            Text(comicResult.title)
                                .font(.custom("WSQuanXing", size: landscapeTitleSize + 4))
                                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                                .foregroundColor(Color(hex: "#B30305"))
                                .multilineTextAlignment(.center)
                                .padding(.bottom, 40)
                                // 硬描边（外描边）通过四个方向的零半径阴影模拟 + 柔和发光
                                .shadow(color: Color(hex: "#CEB899"), radius: 0, x: 2, y: 0)
                                .shadow(color: Color(hex: "#CEB899"), radius: 0, x: -2, y: 0)
                                .shadow(color: Color(hex: "#CEB899"), radius: 0, x: 0, y: 2)
                                .shadow(color: Color(hex: "#CEB899"), radius: 0, x: 0, y: -2)
                                .shadow(color: Color(hex: "#CEB899"), radius: 2)
                        }
                        .frame(maxWidth: .infinity, maxHeight: landscapeImageHeight)
                    }
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)

            // 右侧：文本和按钮区域
            VStack(spacing: landscapeContentSpacing) {
                Spacer()

                // 显示连环画标题
                Text(comicResult.title)
                    .font(.custom("STKaiti", size: landscapeTitleSize))
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "#855C23"))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, landscapeTextPadding)

                // 显示故事摘要作为描述
                Text(comicResult.summary ?? "暂无故事摘要")
                    .font(.custom("STKaiti", size: landscapeDescriptionSize))
                    .dynamicTypeSize(...DynamicTypeSize.large)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.18, green: 0.15, blue: 0.09))
                    .opacity(0.6)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .padding(.horizontal, landscapeTextPadding)

                NavigationLink {
                    ComicResultView(comicResult: comicResult)
                } label: {
                    Image("翻开画册")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: landscapeButtonWidth, height: landscapeButtonHeight)
                }

                Spacer()
            }
            .frame(width: landscapeContentWidth)
        }
        .padding(.horizontal, landscapePadding)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// 竖屏布局
    @ViewBuilder
    private var portraitLayout: some View {
        VStack(spacing: portraitSpacing) {
            // 顶部弹性空间
            Spacer(minLength: portraitTopSpacing)

            // 图片区域
            if let firstPanel = comicResult.panels.first {
                ZStack {
                    AsyncImageView(imageUrl: firstPanel.imageUrl)
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: portraitImageHeight)
                    
                    // 图片上的覆盖标题（位于图片底部）
                    VStack {
                        Spacer()

                        Text(comicResult.title)
                            .font(.custom("WSQuanXing", size: landscapeTitleSize + 4))
                            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                            .foregroundColor(Color(hex: "#B30305"))
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 30)
                            // 硬描边（外描边）通过四个方向的零半径阴影模拟 + 柔和发光
                            .shadow(color: Color(hex: "#CEB899"), radius: 0, x: 2, y: 0)
                            .shadow(color: Color(hex: "#CEB899"), radius: 0, x: -2, y: 0)
                            .shadow(color: Color(hex: "#CEB899"), radius: 0, x: 0, y: 2)
                            .shadow(color: Color(hex: "#CEB899"), radius: 0, x: 0, y: -2)
                            .shadow(color: Color(hex: "#CEB899"), radius: 2)
                    }
                    .frame(maxWidth: .infinity, maxHeight: landscapeImageHeight)
                }
            } 

            // 图片和文本之间的弹性间距
            Spacer(minLength: portraitMiddleSpacing)

            // 文本区域
            VStack(spacing: portraitContentSpacing) {
                // 显示连环画标题
                Text(comicResult.title)
                    .font(.custom("STKaiti", size: portraitTitleSize))
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "#2F2617"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, portraitTextPadding)

                // 显示故事摘要作为描述
                Text(comicResult.summary ?? "暂无故事摘要")
                    .font(.custom("STKaiti", size: portraitDescriptionSize))
                    .dynamicTypeSize(...DynamicTypeSize.large)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.18, green: 0.15, blue: 0.09))
                    .opacity(0.6)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .lineSpacing(4)
                    .padding(.horizontal, portraitTextPadding)
            }

            // 文本和按钮之间的弹性间距
            Spacer(minLength: portraitBottomSpacing)

            // 按钮区域
            NavigationLink {
                ComicResultView(comicResult: comicResult)
            } label: {
                Image("翻开画册")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: portraitButtonWidth, height: portraitButtonHeight)
            }

            // 底部弹性空间
            Spacer(minLength: portraitEndSpacing)
        }
        .padding(.horizontal, portraitPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 响应式属性
private extension OpenResultsView {
    var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    // 竖屏属性
    var portraitSpacing: CGFloat { isCompact ? 16 : 24 }
    var portraitTopSpacing: CGFloat { isCompact ? 20 : 40 }
    var portraitMiddleSpacing: CGFloat { isCompact ? 20 : 30 }
    var portraitBottomSpacing: CGFloat { isCompact ? 30 : 50 }
    var portraitEndSpacing: CGFloat { isCompact ? 20 : 40 }
    var portraitPadding: CGFloat { isCompact ? 20 : 40 }
    var portraitContentSpacing: CGFloat { isCompact ? 16 : 20 }
    var portraitTextPadding: CGFloat { isCompact ? 16 : 24 }

    var portraitImageHeight: CGFloat { isCompact ? 280 : 350 }
    var portraitTitleSize: CGFloat { isCompact ? 28 : 32 }
    var portraitDescriptionSize: CGFloat { isCompact ? 18 : 20 }
    var portraitButtonWidth: CGFloat { isCompact ? 250 : 280 }
    var portraitButtonHeight: CGFloat { isCompact ? 45 : 52 }

    // 横屏属性 (根据设备差异化调整)
    var landscapeSpacing: CGFloat {
        horizontalSizeClass == .regular ? 40 : 30
    }
    var landscapePadding: CGFloat {
        horizontalSizeClass == .regular ? 35 : 25
    }
    var landscapeContentSpacing: CGFloat {
        horizontalSizeClass == .regular ? 20 : 15
    }
    var landscapeTextPadding: CGFloat {
        horizontalSizeClass == .regular ? 16 : 12
    }

    var landscapeImageHeight: CGFloat {
        horizontalSizeClass == .regular ? 300 : 250
    }
    var landscapeTitleSize: CGFloat {
        horizontalSizeClass == .regular ? 26 : 24
    }
    var landscapeDescriptionSize: CGFloat {
        horizontalSizeClass == .regular ? 18 : 16
    }
    var landscapeButtonWidth: CGFloat {
        horizontalSizeClass == .regular ? 220 : 200
    }
    var landscapeButtonHeight: CGFloat {
        horizontalSizeClass == .regular ? 40 : 35
    }
    var landscapeContentWidth: CGFloat {
        horizontalSizeClass == .regular ? 280 : 240
    }
}
