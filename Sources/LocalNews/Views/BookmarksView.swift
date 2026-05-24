import SwiftUI

struct BookmarksView: View {
    @EnvironmentObject var store: AppStore
    @Binding var selectedItem: FeedItem?

    var body: some View {
        List(selection: $selectedItem) {
            ForEach(store.bookmarks) { bookmark in
                FeedRowView(item: bookmark.item)
                    .tag(bookmark.item)
                    .contextMenu {
                        Button("Remove Bookmark", role: .destructive) {
                            store.removeBookmark(id: bookmark.itemID)
                            if selectedItem?.id == bookmark.itemID { selectedItem = nil }
                        }
                        Button("Open in Browser") {
                            NSWorkspace.shared.open(bookmark.item.url)
                        }
                    }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Bookmarks")
        .navigationSplitViewColumnWidth(min: 280, ideal: 340)
        .overlay {
            if store.bookmarks.isEmpty {
                ContentUnavailableView("No Bookmarks", systemImage: "bookmark.slash",
                                       description: Text("Right-click any article to bookmark it"))
            }
        }
    }
}
