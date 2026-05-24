import SwiftUI
import Combine

/// Central observable state. Views read from here; services write to here.
@MainActor
final class AppStore: ObservableObject {
    @Published var items: [FeedItem] = []
    @Published var bookmarks: [Bookmark] = []
    @Published var snippets: [Snippet] = []
    @Published var readingLists: [ReadingList] = []
    @Published var sources: [NewsSource] = NewsSource.defaults
    @Published var weather: WeatherData?
    @Published var isRefreshing = false
    @Published var lastRefreshed: Date?
    @Published var fetchErrors: [String: String] = [:]   // sourceName → error message

    private let persistence = PersistenceService()
    private var refreshTask: Task<Void, Never>?
    private var autoRefreshTimer: Timer?

    init() {
        load()
        scheduleAutoRefresh()
    }

    // MARK: - Refresh

    func refreshAll() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        let enabledSources = sources.filter(\.isEnabled)
        var fetched: [FeedItem] = []
        var errors: [String: String] = [:]

        await withTaskGroup(of: (String, [FeedItem], String?).self) { group in
            for source in enabledSources {
                group.addTask {
                    do {
                        switch source.fetchMethod {
                        case .rss(let url):
                            let items = try await RSSService.fetch(url: url, source: source)
                            return (source.name, items, nil)
                        case .scrape(let strategy):
                            let items = try await ScraperService.fetch(strategy: strategy, source: source)
                            return (source.name, items, nil)
                        case .redditJSON(let url):
                            let items = try await RedditService.fetch(url: url, source: source)
                            return (source.name, items, nil)
                        case .nwsWeather:
                            let w = try await WeatherService.fetch()
                            await MainActor.run { self.weather = w }
                            return (source.name, [], nil)
                        }
                    } catch {
                        return (source.name, [], error.localizedDescription)
                    }
                }
            }
            for await (name, items, error) in group {
                fetched.append(contentsOf: items)
                if let error { errors[name] = error }
            }
        }
        fetchErrors = errors

        let existing = Set(items.map(\.id))
        let merged = (fetched.filter { !existing.contains($0.id) } + items)
            .sorted { $0.publishedAt > $1.publishedAt }
        items = merged
        lastRefreshed = .now
        save()
    }

    // MARK: - Bookmarks

    func addBookmark(_ item: FeedItem) {
        guard !bookmarks.contains(where: { $0.itemID == item.id }) else { return }
        bookmarks.append(Bookmark(itemID: item.id, item: item, savedAt: .now))
        save()
    }

    func removeBookmark(id: String) {
        bookmarks.removeAll { $0.itemID == id }
        save()
    }

    func isBookmarked(_ item: FeedItem) -> Bool {
        bookmarks.contains { $0.itemID == item.id }
    }

    // MARK: - Snippets

    func addSnippet(_ text: String, from item: FeedItem? = nil, note: String = "") {
        snippets.append(Snippet(text: text, sourceItem: item, note: note, createdAt: .now))
        save()
    }

    func deleteSnippet(id: UUID) {
        snippets.removeAll { $0.id == id }
        save()
    }

    // MARK: - Reading Lists

    func createReadingList(name: String) {
        readingLists.append(ReadingList(name: name))
        save()
    }

    func addToReadingList(listID: UUID, item: FeedItem) {
        guard let idx = readingLists.firstIndex(where: { $0.id == listID }) else { return }
        readingLists[idx].add(item)
        save()
    }

    func removeFromReadingList(listID: UUID, itemID: String) {
        guard let idx = readingLists.firstIndex(where: { $0.id == listID }) else { return }
        readingLists[idx].remove(itemID: itemID)
        save()
    }

    func deleteReadingList(id: UUID) {
        readingLists.removeAll { $0.id == id }
        save()
    }

    // MARK: - Persistence

    private func load() {
        bookmarks = persistence.load(key: "bookmarks") ?? []
        snippets = persistence.load(key: "snippets") ?? []
        readingLists = persistence.load(key: "readingLists") ?? []
        sources = persistence.load(key: "sources") ?? NewsSource.defaults
        items = persistence.load(key: "items") ?? []
        weather = persistence.load(key: "weather")
    }

    private func save() {
        persistence.save(bookmarks, key: "bookmarks")
        persistence.save(snippets, key: "snippets")
        persistence.save(readingLists, key: "readingLists")
        persistence.save(sources, key: "sources")
        persistence.save(Array(items.prefix(500)), key: "items")
        if let w = weather { persistence.save(w, key: "weather") }
    }

    // MARK: - Auto-refresh

    private func scheduleAutoRefresh() {
        autoRefreshTimer = Timer.scheduledTimer(withTimeInterval: 15 * 60, repeats: true) { [weak self] _ in
            Task { await self?.refreshAll() }
        }
        // Delay by one run-loop tick so the first SwiftUI render completes
        // before we publish changes, avoiding the "publishing during view update" warning.
        Task {
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
            await refreshAll()
        }
    }
}
