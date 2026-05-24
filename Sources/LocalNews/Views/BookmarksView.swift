import SwiftUI

struct BookmarksView: View {
    @EnvironmentObject var store: AppStore
    @State private var selectedItem: FeedItem?

    var body: some View {
        HSplitView {
            List(store.bookmarks, selection: $selectedItem) { bookmark in
                FeedRowView(item: bookmark.item)
                    .tag(bookmark.item)
                    .contextMenu {
                        Button("Remove Bookmark", role: .destructive) {
                            store.removeBookmark(id: bookmark.itemID)
                        }
                        Button("Open in Browser") {
                            NSWorkspace.shared.open(bookmark.item.url)
                        }
                    }
            }
            .listStyle(.plain)
            .frame(minWidth: 260)

            if let item = selectedItem {
                ArticleDetailView(item: item)
            } else {
                ContentUnavailableView("Select a Bookmark",
                                       systemImage: "bookmark",
                                       description: Text("Your saved articles appear here"))
            }
        }
        .navigationTitle("Bookmarks")
        .overlay {
            if store.bookmarks.isEmpty {
                ContentUnavailableView("No Bookmarks", systemImage: "bookmark.slash",
                                       description: Text("Right-click any article to bookmark it"))
            }
        }
    }
}
