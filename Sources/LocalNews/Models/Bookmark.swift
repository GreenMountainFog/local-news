import Foundation

struct Bookmark: Identifiable, Codable {
    let id: UUID
    let itemID: String
    let item: FeedItem
    let savedAt: Date

    init(id: UUID = .init(), itemID: String, item: FeedItem, savedAt: Date) {
        self.id = id
        self.itemID = itemID
        self.item = item
        self.savedAt = savedAt
    }
}

struct Snippet: Identifiable, Codable {
    let id: UUID
    let text: String
    let sourceItem: FeedItem?
    var note: String
    let createdAt: Date

    init(id: UUID = .init(), text: String, sourceItem: FeedItem?, note: String, createdAt: Date) {
        self.id = id
        self.text = text
        self.sourceItem = sourceItem
        self.note = note
        self.createdAt = createdAt
    }
}

struct ReadingList: Identifiable, Codable {
    let id: UUID
    var name: String
    var itemIDs: [String]
    var items: [FeedItem]
    let createdAt: Date

    init(id: UUID = .init(), name: String) {
        self.id = id
        self.name = name
        self.itemIDs = []
        self.items = []
        self.createdAt = .now
    }

    mutating func add(_ item: FeedItem) {
        guard !itemIDs.contains(item.id) else { return }
        itemIDs.append(item.id)
        items.append(item)
    }

    mutating func remove(itemID: String) {
        itemIDs.removeAll { $0 == itemID }
        items.removeAll { $0.id == itemID }
    }
}
