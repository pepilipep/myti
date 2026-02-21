import GRDB

struct Activity: Identifiable, Equatable, Hashable {
    var id: Int64?
    var name: String
    var categoryId: Int64?
    var isActive: Bool
    var createdAt: String?
}

extension Activity: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "activities"

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case categoryId = "category_id"
        case isActive = "is_active"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int64.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        categoryId = try container.decodeIfPresent(Int64.self, forKey: .categoryId)
        let activeInt = try container.decode(Int.self, forKey: .isActive)
        isActive = activeInt != 0
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(categoryId, forKey: .categoryId)
        try container.encode(isActive ? 1 : 0, forKey: .isActive)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
    }
}
