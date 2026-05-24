import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var store: AppStore
    @Binding var destination: SidebarDestination

    var body: some View {
        List(selection: $destination) {
            Section("Feed") {
                Label("All", systemImage: "tray.2")
                    .tag(SidebarDestination.allFeed)
                ForEach(Category.allCases) { cat in
                    Label(cat.displayName, systemImage: cat.systemImage)
                        .tag(SidebarDestination.category(cat))
                        .badge(unread(for: cat))
                }
            }

            Section("Saved") {
                Label("Bookmarks", systemImage: "bookmark")
                    .tag(SidebarDestination.bookmarks)
                Label("Snippets", systemImage: "text.quote")
                    .tag(SidebarDestination.snippets)
            }

            if !store.readingLists.isEmpty {
                Section("Reading Lists") {
                    ForEach(store.readingLists) { list in
                        Label(list.name, systemImage: "list.bullet")
                            .tag(SidebarDestination.readingList(list.id))
                            .contextMenu {
                                Button("Delete", role: .destructive) {
                                    store.deleteReadingList(id: list.id)
                                    if destination == .readingList(list.id) {
                                        destination = .allFeed
                                    }
                                }
                            }
                    }
                }
            }

            if store.weather != nil {
                Section("Weather") {
                    Label("Burlington", systemImage: "cloud.sun")
                        .tag(SidebarDestination.weather)
                }
            }

            if !store.fetchErrors.isEmpty {
                Section("Source Errors") {
                    ForEach(Array(store.fetchErrors.keys.sorted()), id: \.self) { name in
                        VStack(alignment: .leading, spacing: 2) {
                            Label(name, systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                                .font(.caption)
                            Text(store.fetchErrors[name] ?? "")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Local News")
        .navigationSplitViewColumnWidth(min: 180, ideal: 220)
        .toolbar {
            ToolbarItem {
                Button {
                    store.createReadingList(name: "New List")
                } label: {
                    Image(systemName: "plus")
                }
                .help("New Reading List")
            }
        }
    }

    private func unread(for cat: Category) -> Int {
        store.items.filter { $0.category == cat && !$0.isRead }.count
    }
}
