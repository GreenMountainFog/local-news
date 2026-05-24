import SwiftUI

struct ReadingListDetailView: View {
    let list: ReadingList
    @EnvironmentObject var store: AppStore
    @Binding var selectedItem: FeedItem?
    @State private var isRenaming = false
    @State private var newName = ""

    private var currentList: ReadingList {
        store.readingLists.first { $0.id == list.id } ?? list
    }

    var body: some View {
        List(selection: $selectedItem) {
            ForEach(currentList.items) { item in
                FeedRowView(item: item)
                    .tag(item)
                    .contextMenu {
                        Button("Remove from List", role: .destructive) {
                            store.removeFromReadingList(listID: list.id, itemID: item.id)
                            if selectedItem?.id == item.id { selectedItem = nil }
                        }
                        Button("Open in Browser") { NSWorkspace.shared.open(item.url) }
                    }
            }
        }
        .listStyle(.plain)
        .navigationTitle(currentList.name)
        .navigationSplitViewColumnWidth(min: 280, ideal: 340)
        .overlay {
            if currentList.items.isEmpty {
                ContentUnavailableView("Empty List", systemImage: "list.bullet",
                                       description: Text("Right-click any article and choose Add to Reading List"))
            }
        }
        .toolbar {
            ToolbarItem {
                Button("Rename") {
                    newName = currentList.name
                    isRenaming = true
                }
            }
        }
        .sheet(isPresented: $isRenaming) {
            RenameListSheet(listID: list.id, currentName: newName)
        }
    }
}

struct RenameListSheet: View {
    let listID: UUID
    let currentName: String
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    @State private var name: String

    init(listID: UUID, currentName: String) {
        self.listID = listID
        self.currentName = currentName
        _name = State(initialValue: currentName)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Rename List").font(.headline)
            TextField("List name", text: $name)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("Cancel", role: .cancel) { dismiss() }.keyboardShortcut(.cancelAction)
                Spacer()
                Button("Rename") {
                    if let idx = store.readingLists.firstIndex(where: { $0.id == listID }) {
                        store.readingLists[idx].name = name
                    }
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 300)
    }
}
