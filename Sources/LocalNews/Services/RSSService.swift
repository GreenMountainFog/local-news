import Foundation

/// Fetches and parses RSS 2.0 / Atom feeds.
struct RSSService {
    static func fetch(url: URL, source: NewsSource) async throws -> [FeedItem] {
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue("LocalNews/1.0 (macOS)", forHTTPHeaderField: "User-Agent")
        let (data, _) = try await URLSession.shared.data(for: request)
        return try parse(data: data, source: source)
    }

    private static func parse(data: Data, source: NewsSource) throws -> [FeedItem] {
        let parser = RSSParser()
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = parser
        xmlParser.parse()
        return parser.items.compactMap { raw -> FeedItem? in
            guard let urlStr = raw.link, let url = URL(string: urlStr) else { return nil }
            return FeedItem(
                id: urlStr,
                title: raw.title ?? "(no title)",
                summary: raw.description?.strippingHTML(),
                url: url,
                sourceName: source.name,
                category: source.category,
                publishedAt: raw.pubDate ?? .now,
                imageURL: raw.imageURL.flatMap(URL.init)
            )
        }
    }
}

private final class RSSParser: NSObject, XMLParserDelegate {
    struct RawItem {
        var title: String?
        var link: String?
        var description: String?
        var pubDate: Date?
        var imageURL: String?
    }

    private(set) var items: [RawItem] = []
    private var current = RawItem()
    private var currentText = ""
    private var inItem = false
    private var inEntry = false  // Atom

    private static let dateFormatters: [DateFormatter] = {
        let rfc822 = DateFormatter()
        rfc822.locale = Locale(identifier: "en_US_POSIX")
        rfc822.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        let iso = ISO8601DateFormatter()
        return [rfc822]
    }()

    func parser(_ parser: XMLParser, didStartElement el: String, namespaceURI: String?,
                qualifiedName: String?, attributes attrs: [String: String] = [:]) {
        if el == "item" || el == "entry" { inItem = true; current = RawItem() }
        if inItem, el == "enclosure", let url = attrs["url"] { current.imageURL = url }
        if inItem, el == "media:content", let url = attrs["url"] { current.imageURL = url }
        if inItem, el == "media:thumbnail", let url = attrs["url"] { current.imageURL = url }
        currentText = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(_ parser: XMLParser, didEndElement el: String, namespaceURI: String?, qualifiedName: String?) {
        guard inItem else { return }
        switch el {
        case "title":       current.title = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        case "link":        if current.link == nil { current.link = currentText.trimmingCharacters(in: .whitespacesAndNewlines) }
        case "description", "summary", "content": current.description = currentText
        case "pubDate", "published", "updated":
            let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
            current.pubDate = Self.dateFormatters.lazy.compactMap { $0.date(from: text) }.first
                ?? ISO8601DateFormatter().date(from: text)
        case "item", "entry":
            items.append(current)
            inItem = false
        default: break
        }
        currentText = ""
    }
}

private extension String {
    func strippingHTML() -> String {
        guard self.contains("<") else { return self }
        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
