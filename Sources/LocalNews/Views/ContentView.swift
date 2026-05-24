import SwiftUI

enum SidebarDestination: Hashable {
    case allFeed
    case category(Category)
    case bookmarks
    case snippets
    case readingList(UUID)
    case weather
}

struct ContentView: View {
    @EnvironmentObject var store: AppStore
    @State private var destination: SidebarDestination = .allFeed
    @State private var selectedItem: FeedItem?

    var body: some View {
        NavigationSplitView {
            SidebarView(destination: $destination)
        } content: {
            contentColumn
        } detail: {
            if let item = selectedItem {
                ArticleDetailView(item: item)
            } else {
                ContentUnavailableView("Select an article", systemImage: "newspaper")
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .task { await store.refreshAll() }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await store.refreshAll() }
                } label: {
                    if store.isRefreshing {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .help("Refresh all sources")
                .disabled(store.isRefreshing)
            }
        }
    }

    @ViewBuilder
    private var contentColumn: some View {
        switch destination {
        case .allFeed:
            FeedView(category: nil, selectedItem: $selectedItem)
        case .category(let cat):
            FeedView(category: cat, selectedItem: $selectedItem)
        case .bookmarks:
            BookmarksView(selectedItem: $selectedItem)
        case .snippets:
            SnippetsView()
        case .readingList(let id):
            if let list = store.readingLists.first(where: { $0.id == id }) {
                ReadingListDetailView(list: list, selectedItem: $selectedItem)
            } else {
                ContentUnavailableView("List not found", systemImage: "list.bullet")
            }
        case .weather:
            if let w = store.weather {
                WeatherView(data: w)
            } else {
                ContentUnavailableView("Weather unavailable", systemImage: "cloud",
                                       description: Text("Refresh to try again"))
            }
        }
    }
}
