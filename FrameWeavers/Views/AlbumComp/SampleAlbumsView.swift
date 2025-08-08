import SwiftUI
import SwiftData

struct SampleAlbumsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SampleAlbumsViewModel()

    var body: some View {
        NavigationStack {
            List {
                // 历史记录部分
                if viewModel.hasHistory {
                    Section {
                        ForEach(viewModel.historyAlbums, id: \.id) { historyAlbum in
                            AlbumRowView(
                                title: historyAlbum.title,
                                description: HistoryAlbumDisplayModel(from: historyAlbum).description,
                                comicResult: historyAlbum.toComicResult(),
                                coverImage: historyAlbum.thumbnailImageName ?? "",
                                isRemoteImage: true,
                                isSampleAlbum: false,
                                onDelete: { viewModel.deleteHistoryAlbum(historyAlbum) }
                            )
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        }
                        .onDelete(perform: viewModel.deleteHistoryAlbums)
                    } header: {
                        HStack {
                            Text("我的画册")
                                .font(.custom("WSQuanXing", size: 20))
                                .foregroundColor(Color(hex: "#855C23"))

                            Spacer()

                            Text("\(viewModel.historyCount)个")
                                .font(.custom("STKaiti", size: 14))
                                .foregroundColor(Color(hex: "#2F2617"))
                                .opacity(0.6)
                        }
                        .padding(.horizontal, 4)
                        .textCase(nil)
                    }
                }

                // 示例画册部分
                Section {
                    ForEach(viewModel.sampleAlbums) { album in
                        AlbumRowView(
                            title: album.title,
                            description: album.description,
                            comicResult: album.comicResult,
                            coverImage: album.coverImage,
                            isRemoteImage: false,
                            isSampleAlbum: true,
                            onDelete: nil
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    }
                } header: {
                    HStack {
                        Text("示例画册")
                            .font(.custom("WSQuanXing", size: 20))
                            .foregroundColor(Color(hex: "#855C23"))
                    }
                }
            }
            .background {
                Image("背景单色")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("画册库")
                        .font(.custom("WSQuanXing", size: 20))
                        .foregroundColor(Color(hex: "#855C23"))
                        .fontWeight(.medium)
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                    .font(.custom("STKaiti", size: 16))
                    .foregroundColor(Color(hex: "#855C23"))
                }
            }
        }
        .onAppear {
            // 初始化ViewModel的历史记录服务
            viewModel.setHistoryService(modelContext: modelContext)
        }
    }
}

// MARK: - 画册行视图

struct AlbumRowView: View {
    let title: String
    let description: String
    let comicResult: ComicResult?
    let coverImage: String
    let isRemoteImage: Bool
    let isSampleAlbum: Bool
    let onDelete: (() -> Void)?

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        if let comicResult = comicResult {
            // 有内容的画册 - 可以点击
            NavigationLink {
                if isSampleAlbum {
                    // 示例画册：保留完整流程（风格选择 -> 处理 -> 结果）
                    SampleFlowView(comicResult: comicResult)
                } else {
                    // 历史画册：直接跳转到结果页面
                    OpenResultsView(comicResult: comicResult)
                }
            } label: {
                albumRowContent
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            // 无内容的画册 - 不可点击
            albumRowContent
                .opacity(0.6)
        }
    }

    private var albumRowContent: some View {
        HStack(spacing: horizontalSizeClass == .compact ? 12 : 20) {
            // 封面图片
            Group {
                if isRemoteImage {
                    if !coverImage.isEmpty {
                        // 使用 AsyncImageView 支持本地缓存图片
                        AsyncImageView(imageUrl: coverImage)
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    }
                } else {
                    Image(coverImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }
            .frame(width: horizontalSizeClass == .compact ? 60 : 80, 
                   height: horizontalSizeClass == .compact ? 80 : 100)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .clipped()

            // 画册信息
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom("WSQuanXing", size: horizontalSizeClass == .compact ? 16 : 18))
                    .foregroundColor(Color(hex: "#2F2617"))
                    .lineLimit(1)

                Text(description)
                    .font(.custom("STKaiti", size: horizontalSizeClass == .compact ? 14 : 16))
                    .foregroundColor(Color(hex: "#855C23"))
                    .opacity(0.8)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    SampleAlbumsView()
}