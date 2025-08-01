import SwiftUI
import SwiftData

struct SampleAlbumsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = SampleAlbumsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Image("背景单色")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("画册库")
                        .font(.custom("WSQuanXing", size: 28))
                        .foregroundColor(Color(hex: "#855C23"))
                        .padding(.top, 20)

                    List {
                        // 历史记录部分
                        if viewModel.hasHistory {
                            Section {
                                ForEach(viewModel.historyAlbums) { historyAlbum in
                                    HistoryAlbumRowView(
                                        historyAlbum: historyAlbum,
                                        onDelete: { viewModel.deleteHistoryAlbum(historyAlbum) }
                                    )
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
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
                                SampleAlbumRowView(album: album)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                            }
                        } header: {
                            HStack {
                                Text("示例画册")
                                    .font(.custom("WSQuanXing", size: 20))
                                    .foregroundColor(Color(hex: "#855C23"))

                                Spacer()
                            }
                            .padding(.horizontal, 4)
                            .textCase(nil)
                        }
                    }
                    // .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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

// MARK: - 历史画册行视图

struct HistoryAlbumRowView: View {
    let historyAlbum: HistoryAlbum
    let onDelete: () -> Void

    var body: some View {
        if let comicResult = historyAlbum.toComicResult() {
            // 有内容的历史画册 - 可以点击
            NavigationLink {
                SampleFlowView(comicResult: comicResult)
            } label: {
                historyAlbumRowContent
            }
        } else {
            // 数据损坏的画册 - 不可点击
            historyAlbumRowContent
                .opacity(0.6)
        }
    }

    private var historyAlbumRowContent: some View {
        HStack(spacing: 16) {
            // 封面图片或占位符
            Group {
                if let thumbnailImageName = historyAlbum.thumbnailImageName,
                   !thumbnailImageName.isEmpty {
                    AsyncImage(url: URL(string: thumbnailImageName)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    }
                } else {
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 80, height: 100)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .shadow(radius: 4)

            // 画册信息
            VStack(alignment: .leading, spacing: 8) {
                Text(historyAlbum.title)
                    .font(.custom("WSQuanXing", size: 18))
                    .foregroundColor(Color(hex: "#2F2617"))
                    .lineLimit(2)

                Text("\(historyAlbum.panelCount)页 · \(DateFormatter.shortDate.string(from: historyAlbum.creationDate))")
                    .font(.custom("STKaiti", size: 14))
                    .foregroundColor(Color(hex: "#855C23"))
                    .opacity(0.8)

                Text("来自: \(historyAlbum.originalVideoTitle)")
                    .font(.custom("STKaiti", size: 12))
                    .foregroundColor(Color(hex: "#2F2617"))
                    .opacity(0.6)
                    .lineLimit(1)

                Spacer()
            }

            Spacer()

            // 删除按钮
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .font(.system(size: 16))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(16)
        .background(Color.white.opacity(0.9))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        // .padding(.horizontal, 8)
    }
}

// MARK: - 示例画册行视图

struct SampleAlbumRowView: View {
    let album: SampleAlbum

    var body: some View {
        if let comicResult = album.comicResult {
            // 有内容的画册 - 可以点击
            NavigationLink {
                SampleFlowView(comicResult: comicResult)
            } label: {
                albumRowContent
            }
        } else {
            // 空白画册 - 不可点击
            albumRowContent
                .opacity(0.6)
        }
    }

    private var albumRowContent: some View {
        HStack(spacing: 16) {
            // 封面图片
            Image(album.coverImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 100)
                .cornerRadius(8)
                .shadow(radius: 4)

            // 画册信息
            VStack(alignment: .leading, spacing: 8) {
                Text(album.title)
                    .font(.custom("WSQuanXing", size: 18))
                    .foregroundColor(Color(hex: "#2F2617"))
                    .lineLimit(2)

                Text(album.description)
                    .font(.custom("STKaiti", size: 14))
                    .foregroundColor(Color(hex: "#855C23"))
                    .opacity(0.8)
                    .lineLimit(2)

                Spacer()

                if album.comicResult != nil {
                    Text("点击阅读")
                        .font(.custom("STKaiti", size: 12))
                        .foregroundColor(Color(hex: "#2F2617"))
                        .opacity(0.6)
                } else {
                    Text("敬请期待")
                        .font(.custom("STKaiti", size: 12))
                        .foregroundColor(Color.gray)
                }
            }

            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.9))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        // .padding(.horizontal, 8)
    }
}

#Preview {
    SampleAlbumsView()
}
