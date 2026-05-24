import Foundation

enum FetchMethod: Codable {
    case rss(URL)
    case scrape(ScrapeStrategy)
    case redditJSON(URL)
    case nwsWeather
}

enum ScrapeStrategy: String, Codable {
    case higherGround
    case helloBurlington
    case helloBurlingtonEvents
    case helloBurlingtonConcerts
    case bandsInTown
    case btownBrief
}

struct NewsSource: Identifiable, Codable {
    let id: UUID
    var name: String
    var fetchMethod: FetchMethod
    var category: Category
    var isEnabled: Bool

    init(id: UUID = .init(), name: String, fetchMethod: FetchMethod, category: Category, isEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.fetchMethod = fetchMethod
        self.category = category
        self.isEnabled = isEnabled
    }

    static let defaults: [NewsSource] = [
        // News — RSS
        .init(name: "VTDigger",         fetchMethod: .rss(URL(string: "https://vtdigger.org/feed/")!),                                         category: .news),
        .init(name: "Seven Days",       fetchMethod: .rss(URL(string: "https://www.sevendaysvt.com/feed/")!),                                  category: .news),
        .init(name: "Vermont Public",   fetchMethod: .rss(URL(string: "https://www.vermontpublic.org/feed")!),                                 category: .news),
        .init(name: "WCAX",             fetchMethod: .rss(URL(string: "https://www.wcax.com/rss")!),                                           category: .news),
        .init(name: "MyNBC5",           fetchMethod: .rss(URL(string: "https://www.mynbc5.com/rss")!),                                         category: .news),
        .init(name: "Burlington Free Press", fetchMethod: .rss(URL(string: "https://www.burlingtonfreepress.com/rss/")!),                     category: .news),
        .init(name: "My Champlain Valley", fetchMethod: .rss(URL(string: "https://www.mychamplainvalley.com/feed/")!),                        category: .news),
        .init(name: "Vermont Standard", fetchMethod: .rss(URL(string: "https://thevermontstandard.com/feed/")!),                              category: .news),
        .init(name: "Vermont.gov",      fetchMethod: .rss(URL(string: "https://www.vermont.gov/latest-news/feed")!),                          category: .news),
        // News — scraped
        .init(name: "B-Town Brief",     fetchMethod: .scrape(.btownBrief),                                                                     category: .news),
        // Community
        .init(name: "r/burlington",     fetchMethod: .redditJSON(URL(string: "https://www.reddit.com/r/burlington/.json")!),                  category: .news),
        // Events — scraped
        .init(name: "Higher Ground",    fetchMethod: .scrape(.higherGround),                                                                   category: .events),
        .init(name: "Hello Burlington (Events)", fetchMethod: .scrape(.helloBurlingtonEvents),                                                 category: .events),
        .init(name: "Hello Burlington (Concerts)", fetchMethod: .scrape(.helloBurlingtonConcerts),                                             category: .events),
        .init(name: "Bands In Town",    fetchMethod: .scrape(.bandsInTown),                                                                    category: .events),
        // Weather
        .init(name: "NWS Burlington",   fetchMethod: .nwsWeather,                                                                             category: .weather),
    ]
}
