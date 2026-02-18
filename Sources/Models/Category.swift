import GRDB

struct Category: Identifiable, Equatable, Hashable {
    var id: Int64?
    var name: String
    var color: String
    var sortOrder: Int
    var isActive: Bool
    var createdAt: String?
}

extension Category: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "categories"

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case color
        case sortOrder = "sort_order"
        case isActive = "is_active"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int64.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        color = try container.decode(String.self, forKey: .color)
        sortOrder = try container.decode(Int.self, forKey: .sortOrder)
        // is_active is stored as INTEGER 0/1
        let activeInt = try container.decode(Int.self, forKey: .isActive)
        isActive = activeInt != 0
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(color, forKey: .color)
        try container.encode(sortOrder, forKey: .sortOrder)
        try container.encode(isActive ? 1 : 0, forKey: .isActive)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
    }
}
