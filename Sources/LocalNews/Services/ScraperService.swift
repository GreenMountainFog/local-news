import Foundation
import SwiftSoup

/// HTML scraper for sources that don't publish RSS feeds.
struct ScraperService {
    static func fetch(strategy: ScrapeStrategy, source: NewsSource) async throws -> [FeedItem] {
        switch strategy {
        case .higherGround:         return try await scrapeHigherGround(source: source)
        case .helloBurlington:      return try await scrapeHelloBurlington(source: source)
        case .helloBurlingtonEvents: return try await scrapeHelloBurlingtonEvents(source: source)
        case .helloBurlingtonConcerts: return try await scrapeHelloBurlingtonConcerts(source: source)
        case .bandsInTown:          return try await scrapeBandsInTown(source: source)
        case .btownBrief:           return try await scrapeBtownBrief(source: source)
        }
    }

    // MARK: - Helpers

    private static func html(from urlString: String) async throws -> Document {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url, timeoutInterval: 15)
        req.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        let (data, _) = try await URLSession.shared.data(for: req)
        let html = String(data: data, encoding: .utf8) ?? ""
        return try SwiftSoup.parse(html)
    }

    // MARK: - Higher Ground (highergroundmusic.com)

    private static func scrapeHigherGround(source: NewsSource) async throws -> [FeedItem] {
        let doc = try await html(from: "https://www.highergroundmusic.com/events/")
        let events = try doc.select(".event-item, .event-listing, article.event, .tribe-events-calendar-list__event")
        return try events.compactMap { el -> FeedItem? in
            let title = try el.select(".event-title, h2, h3, .tribe-event-url").text()
            let link = try el.select("a").first()?.attr("href") ?? ""
            let dateText = try el.select(".event-date, .tribe-event-date-start, time").text()
            guard !title.isEmpty, let url = absoluteURL(link, base: "https://www.highergroundmusic.com") else { return nil }
            return FeedItem(id: url.absoluteString, title: title, summary: dateText.isEmpty ? nil : dateText,
                            url: url, sourceName: source.name, category: .events,
                            publishedAt: parseEventDate(dateText) ?? .now, imageURL: nil)
        }
    }

    // MARK: - Hello Burlington

    private static func scrapeHelloBurlington(source: NewsSource) async throws -> [FeedItem] {
        let doc = try await html(from: "https://www.helloburlingtonvt.com")
        let articles = try doc.select("article, .post, .entry")
        return try articles.compactMap { el -> FeedItem? in
            let title = try el.select("h2, h3, .entry-title").text()
            let link = try el.select("a").first()?.attr("href") ?? ""
            let summary = try el.select(".entry-summary, .excerpt, p").first()?.text()
            guard !title.isEmpty, let url = absoluteURL(link, base: "https://www.helloburlingtonvt.com") else { return nil }
            return FeedItem(id: url.absoluteString, title: title, summary: summary,
                            url: url, sourceName: source.name, category: source.category,
                            publishedAt: .now, imageURL: nil)
        }
    }

    private static func scrapeHelloBurlingtonEvents(source: NewsSource) async throws -> [FeedItem] {
        let doc = try await html(from: "https://www.helloburlingtonvt.com/events/")
        return try scrapeEventCards(doc: doc, base: "https://www.helloburlingtonvt.com", source: source)
    }

    private static func scrapeHelloBurlingtonConcerts(source: NewsSource) async throws -> [FeedItem] {
        let doc = try await html(from: "https://www.helloburlingtonvt.com/events/concerts-live-music/")
        return try scrapeEventCards(doc: doc, base: "https://www.helloburlingtonvt.com", source: source)
    }

    private static func scrapeEventCards(doc: Document, base: String, source: NewsSource) throws -> [FeedItem] {
        let cards = try doc.select(".event-card, .tribe-event, article, .event-item")
        return try cards.compactMap { el -> FeedItem? in
            let title = try el.select("h2, h3, .tribe-event-url, .event-title").text()
            let link = try el.select("a").first()?.attr("href") ?? ""
            let dateText = try el.select("time, .tribe-event-date-start, .event-date").text()
            guard !title.isEmpty, let url = absoluteURL(link, base: base) else { return nil }
            return FeedItem(id: url.absoluteString, title: title, summary: dateText.isEmpty ? nil : dateText,
                            url: url, sourceName: source.name, category: .events,
                            publishedAt: parseEventDate(dateText) ?? .now, imageURL: nil)
        }
    }

    // MARK: - Bands In Town (Burlington, VT)

    private static func scrapeBandsInTown(source: NewsSource) async throws -> [FeedItem] {
        let doc = try await html(from: "https://www.bandsintown.com/c/burlington-vt")
        let events = try doc.select("[data-event-id], .event-card, article")
        return try events.compactMap { el -> FeedItem? in
            let title = try el.select("h2, h3, .artist-name, strong").text()
            let link = try el.select("a").first()?.attr("href") ?? ""
            let venue = try el.select(".venue-name, .location").text()
            let dateText = try el.select("time, .date").text()
            guard !title.isEmpty else { return nil }
            let url = absoluteURL(link, base: "https://www.bandsintown.com")
                ?? URL(string: "https://www.bandsintown.com/c/burlington-vt")!
            return FeedItem(id: link.isEmpty ? title : link, title: title,
                            summary: [venue, dateText].filter { !$0.isEmpty }.joined(separator: " · "),
                            url: url, sourceName: source.name, category: .events,
                            publishedAt: parseEventDate(dateText) ?? .now, imageURL: nil)
        }
    }

    // MARK: - B-Town Brief

    private static func scrapeBtownBrief(source: NewsSource) async throws -> [FeedItem] {
        let doc = try await html(from: "https://www.btownbrief.com")
        let articles = try doc.select("article, .post, .story")
        return try articles.compactMap { el -> FeedItem? in
            let title = try el.select("h1, h2, h3").first()?.text() ?? ""
            let link = try el.select("a").first()?.attr("href") ?? ""
            let summary = try el.select("p").first()?.text()
            guard !title.isEmpty, let url = absoluteURL(link, base: "https://www.btownbrief.com") else { return nil }
            return FeedItem(id: url.absoluteString, title: title, summary: summary,
                            url: url, sourceName: source.name, category: .news,
                            publishedAt: .now, imageURL: nil)
        }
    }

    // MARK: - Utilities

    private static func absoluteURL(_ href: String, base: String) -> URL? {
        let trimmed = href.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.hasPrefix("http") { return URL(string: trimmed) }
        if trimmed.hasPrefix("/") { return URL(string: base + trimmed) }
        return URL(string: base + "/" + trimmed)
    }

    private static func parseEventDate(_ text: String) -> Date? {
        let formatters: [DateFormatter] = [
            { let f = DateFormatter(); f.dateFormat = "MMMM d, yyyy"; f.locale = .init(identifier: "en_US"); return f }(),
            { let f = DateFormatter(); f.dateFormat = "EEE, MMM d"; f.locale = .init(identifier: "en_US"); return f }(),
            { let f = DateFormatter(); f.dateFormat = "MMM d"; f.locale = .init(identifier: "en_US"); return f }(),
        ]
        for fmt in formatters {
            if let d = fmt.date(from: text.trimmingCharacters(in: .whitespacesAndNewlines)) { return d }
        }
        return nil
    }
}
