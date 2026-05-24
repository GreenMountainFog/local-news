import SwiftUI

struct SnippetsView: View {
    @EnvironmentObject var store: AppStore
    @State private var selected: Snippet?
    @State private var editingNote = ""

    var body: some View {
        HSplitView {
            List(store.snippets.sorted { $0.createdAt > $1.createdAt }, selection: $selected) { snippet in
                VStack(alignment: .leading, spacing: 4) {
                    Text(snippet.text)
                        .lineLimit(3)
                        .font(.subheadline)
                    if !snippet.note.isEmpty {
                        Text(snippet.note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let source = snippet.sourceItem {
                        Text(source.sourceName)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.vertical, 4)
                .tag(snippet)
                .contextMenu {
                    Button("Delete", role: .destructive) {
                        store.deleteSnippet(id: snippet.id)
                        if selected?.id == snippet.id { selected = nil }
                    }
                    Button("Copy Text") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(snippet.text, forType: .string)
                    }
                }
            }
            .listStyle(.plain)
            .frame(minWidth: 240)

            if let snippet = selected {
                SnippetDetailView(snippet: snippet)
            } else {
                ContentUnavailableView("Select a Snippet", systemImage: "text.quote")
            }
        }
        .navigationTitle("Snippets")
        .overlay {
            if store.snippets.isEmpty {
                ContentUnavailableView("No Snippets",
                                       systemImage: "text.quote",
                                       description: Text("Use the quote button in any article to save a snippet"))
            }
        }
    }
}

struct SnippetDetailView: View {
    let snippet: Snippet
    @EnvironmentObject var store: AppStore
    @State private var note: String

    init(snippet: Snippet) {
        self.snippet = snippet
        _note = State(initialValue: snippet.note)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let source = snippet.sourceItem {
                    HStack {
                        Text(source.sourceName).font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Text(snippet.createdAt, style: .date).font(.caption2).foregroundStyle(.tertiary)
                    }
                    Button(source.title) { NSWorkspace.shared.open(source.url) }
                        .buttonStyle(.plain)
                        .font(.subheadline)
                        .foregroundStyle(.accent)
                    Divider()
                }

                Text(snippet.text)
                    .font(.body)
                    .textSelection(.enabled)

                Divider()
                Text("Note").font(.caption).foregroundStyle(.secondary)
                TextEditor(text: $note)
                    .frame(minHeight: 80)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(.separator))
            }
            .padding(20)
        }
    }
}
