import Foundation

/// JSON-on-disk persistence in Application Support.
final class PersistenceService {
    private let directory: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        directory = appSupport.appendingPathComponent("LocalNews", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func save<T: Encodable>(_ value: T, key: String) {
        let url = directory.appendingPathComponent("\(key).json")
        do {
            let data = try JSONEncoder().encode(value)
            try data.write(to: url, options: .atomicWrite)
        } catch {
            print("[Persistence] Failed to save \(key): \(error)")
        }
    }

    func load<T: Decodable>(key: String) -> T? {
        let url = directory.appendingPathComponent("\(key).json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    func delete(key: String) {
        let url = directory.appendingPathComponent("\(key).json")
        try? FileManager.default.removeItem(at: url)
    }
}
