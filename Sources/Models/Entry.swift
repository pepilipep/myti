import GRDB

struct Entry: Identifiable, Equatable {
    var id: Int64?
    var categoryId: Int64
    var promptedAt: String
    var respondedAt: String
    var creditedMinutes: Double
    var createdAt: String?
}

extension Entry: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "entries"

    enum CodingKeys: String, CodingKey {
        case id
        case categoryId = "category_id"
        case promptedAt = "prompted_at"
        case respondedAt = "responded_at"
        case creditedMinutes = "credited_minutes"
        case createdAt = "created_at"
    }
}
