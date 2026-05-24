import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        List(selection: $store.selectedCategory) {
            Section("Feed") {
                Label("All", systemImage: "tray.2")
                    .tag(Optional<Category>.none)
                ForEach(Category.allCases) { cat in
                    Label(cat.displayName, systemImage: cat.systemImage)
                        .tag(Optional(cat))
                        .badge(store.items.filter { $0.category == cat && !$0.isRead }.count)
                }
            }

            Section("Saved") {
                NavigationLink {
                    BookmarksView()
                } label: {
                    Label("Bookmarks", systemImage: "bookmark")
                }
                NavigationLink {
                    SnippetsView()
                } label: {
                    Label("Snippets", systemImage: "text.quote")
                }
            }

            Section("Reading Lists") {
                ForEach(store.readingLists) { list in
                    NavigationLink {
                        ReadingListDetailView(list: list)
                    } label: {
                        Label(list.name, systemImage: "list.bullet")
                    }
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            store.deleteReadingList(id: list.id)
                        }
                    }
                }
                Button {
                    store.createReadingList(name: "New List")
                } label: {
                    Label("New List", systemImage: "plus")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.accent)
            }

            if let w = store.weather {
                Section("Weather") {
                    NavigationLink {
                        WeatherView(data: w)
                    } label: {
                        Label("\(w.current.temperature)°F · \(w.current.textDescription)",
                              systemImage: "cloud.sun")
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Local News")
        .navigationSplitViewColumnWidth(min: 180, ideal: 200)
    }
}
