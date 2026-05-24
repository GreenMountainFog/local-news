import SwiftUI
import WebKit

struct ArticleDetailView: View {
    let item: FeedItem
    @EnvironmentObject var store: AppStore
    @State private var showSnippetSheet = false
    @State private var selectedText = ""

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.sourceName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(item.publishedAt, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer()

                Button {
                    store.isBookmarked(item)
                        ? store.removeBookmark(id: item.id)
                        : store.addBookmark(item)
                } label: {
                    Image(systemName: store.isBookmarked(item) ? "bookmark.fill" : "bookmark")
                }
                .buttonStyle(.plain)
                .help(store.isBookmarked(item) ? "Remove Bookmark" : "Bookmark")

                Button {
                    showSnippetSheet = true
                } label: {
                    Image(systemName: "text.quote")
                }
                .buttonStyle(.plain)
                .help("Save Snippet")

                Button {
                    NSWorkspace.shared.open(item.url)
                } label: {
                    Image(systemName: "safari")
                }
                .buttonStyle(.plain)
                .help("Open in Browser")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.bar)

            Divider()

            WebView(url: item.url)
        }
        .navigationTitle(item.title)
        .sheet(isPresented: $showSnippetSheet) {
            SnippetCaptureView(item: item)
        }
    }
}

// MARK: - WebKit wrapper

struct WebView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let view = WKWebView(frame: .zero, configuration: config)
        view.load(URLRequest(url: url))
        return view
    }

    func updateNSView(_ view: WKWebView, context: Context) {
        if view.url != url {
            view.load(URLRequest(url: url))
        }
    }
}

// MARK: - Snippet capture sheet

struct SnippetCaptureView: View {
    let item: FeedItem
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    @State private var text = ""
    @State private var note = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Save Snippet").font(.headline)

            TextEditor(text: $text)
                .frame(minHeight: 80)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(.separator))

            TextField("Note (optional)", text: $note)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") {
                    store.addSnippet(text, from: item, note: note)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 400)
    }
}
