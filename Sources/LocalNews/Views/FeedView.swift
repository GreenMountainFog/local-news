import SwiftUI

struct FeedView: View {
    let category: Category?
    @EnvironmentObject var store: AppStore
    @Binding var selectedItem: FeedItem?
    @State private var searchText = ""

    private var filtered: [FeedItem] {
        var items = store.items
        if let cat = category {
            items = items.filter { $0.category == cat }
        }
        if !searchText.isEmpty {
            items = items.filter {
                $0.title.localizedCaseInsensitiveContains(searchText)
                || ($0.summary?.localizedCaseInsensitiveContains(searchText) ?? false)
                || $0.sourceName.localizedCaseInsensitiveContains(searchText)
            }
        }
        return items
    }

    var body: some View {
        List(selection: $selectedItem) {
            ForEach(filtered) { item in
                FeedRowView(item: item)
                    .tag(item)
                    .contextMenu { contextMenu(for: item) }
            }
        }
        .listStyle(.plain)
        .searchable(text: $searchText, prompt: "Search articles…")
        .navigationTitle(category?.displayName ?? "All")
        .navigationSplitViewColumnWidth(min: 280, ideal: 340)
        .overlay {
            if filtered.isEmpty && !store.isRefreshing {
                if store.items.isEmpty {
                    ContentUnavailableView("No articles yet", systemImage: "newspaper",
                                           description: Text("Press ⌘R to refresh"))
                } else if !searchText.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
        }
    }

    @ViewBuilder
    private func contextMenu(for item: FeedItem) -> some View {
        Button {
            store.isBookmarked(item) ? store.removeBookmark(id: item.id) : store.addBookmark(item)
        } label: {
            Label(store.isBookmarked(item) ? "Remove Bookmark" : "Bookmark",
                  systemImage: store.isBookmarked(item) ? "bookmark.slash" : "bookmark")
        }

        Menu("Add to Reading List") {
            ForEach(store.readingLists) { list in
                Button(list.name) {
                    store.addToReadingList(listID: list.id, item: item)
                }
            }
            Divider()
            Button("New List…") {
                store.createReadingList(name: "New List")
            }
        }

        Divider()

        Button("Open in Browser") {
            NSWorkspace.shared.open(item.url)
        }

        Button("Copy Link") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(item.url.absoluteString, forType: .string)
        }
    }
}

struct FeedRowView: View {
    let item: FeedItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.sourceName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(item.publishedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Text(item.title)
                .font(.headline)
                .lineLimit(2)
                .opacity(item.isRead ? 0.5 : 1)
            if let summary = item.summary {
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}
