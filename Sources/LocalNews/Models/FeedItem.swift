import Foundation

enum Category: String, Codable, CaseIterable, Identifiable {
    case news, events, weather, sports, arts

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .news: return "News"
        case .events: return "Events"
        case .weather: return "Weather"
        case .sports: return "Sports"
        case .arts: return "Arts & Music"
        }
    }

    var systemImage: String {
        switch self {
        case .news: return "newspaper"
        case .events: return "calendar"
        case .weather: return "cloud.sun"
        case .sports: return "sportscourt"
        case .arts: return "music.note"
        }
    }
}

struct FeedItem: Identifiable, Codable, Hashable {
    let id: String           // stable: url string
    let title: String
    let summary: String?
    let url: URL
    let sourceName: String
    let category: Category
    let publishedAt: Date
    let imageURL: URL?
    var isRead: Bool = false

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: FeedItem, rhs: FeedItem) -> Bool { lhs.id == rhs.id }
}
