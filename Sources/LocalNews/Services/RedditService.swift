import Foundation

/// Fetches r/burlington posts via Reddit's public JSON endpoint (no API key).
struct RedditService {
    static func fetch(url: URL, source: NewsSource) async throws -> [FeedItem] {
        var req = URLRequest(url: url, timeoutInterval: 15)
        req.setValue("LocalNews/1.0 (macOS)", forHTTPHeaderField: "User-Agent")
        let (data, _) = try await URLSession.shared.data(for: req)

        struct Root: Decodable {
            struct Data: Decodable {
                struct Child: Decodable {
                    struct Post: Decodable {
                        let id: String; let title: String; let url: String
                        let selftext: String; let created_utc: Double
                        let thumbnail: String?; let permalink: String
                    }
                    let data: Post
                }
                let children: [Child]
            }
            let data: Data
        }

        let root = try JSONDecoder().decode(Root.self, from: data)
        return root.data.children.compactMap { child -> FeedItem? in
            let post = child.data
            guard let articleURL = URL(string: post.url.hasPrefix("/r/")
                ? "https://reddit.com\(post.url)" : post.url) else { return nil }
            let imageURL = post.thumbnail.flatMap { t -> URL? in
                guard t != "self", t != "default", t != "nsfw" else { return nil }
                return URL(string: t)
            }
            return FeedItem(
                id: post.id,
                title: post.title,
                summary: post.selftext.isEmpty ? nil : String(post.selftext.prefix(300)),
                url: articleURL,
                sourceName: source.name,
                category: source.category,
                publishedAt: Date(timeIntervalSince1970: post.created_utc),
                imageURL: imageURL
            )
        }
    }
}
