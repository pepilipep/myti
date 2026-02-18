import GRDB
import Foundation

final class CategoryStore {
    static let shared = CategoryStore()
    private init() {}

    private var db: DatabaseQueue {
        DatabaseManager.shared.dbQueue!
    }

    func listCategories(activeOnly: Bool = true) -> [Category] {
        do {
            return try db.read { db in
                let sql = activeOnly
                    ? "SELECT * FROM categories WHERE is_active = 1 ORDER BY sort_order ASC"
                    : "SELECT * FROM categories ORDER BY sort_order ASC"
                return try Category.fetchAll(db, sql: sql)
            }
        } catch {
            Logger.shared.error("listCategories failed", error: error)
            return []
        }
    }

    func upsert(_ data: Category) -> Category? {
        do {
            return try db.write { db in
                if let existingId = data.id {
                    try db.execute(
                        sql: "UPDATE categories SET name = ?, color = ?, sort_order = ?, is_active = ? WHERE id = ?",
                        arguments: [data.name, data.color, data.sortOrder, data.isActive ? 1 : 0, existingId]
                    )
                    return try Category.fetchOne(db, sql: "SELECT * FROM categories WHERE id = ?", arguments: [existingId])
                } else {
                    let maxOrder = try Int.fetchOne(db, sql: "SELECT MAX(sort_order) FROM categories") ?? -1
                    let order = data.sortOrder != 0 ? data.sortOrder : maxOrder + 1
                    try db.execute(
                        sql: "INSERT INTO categories (name, color, sort_order) VALUES (?, ?, ?)",
                        arguments: [data.name, data.color, order]
                    )
                    let id = db.lastInsertedRowID
                    return try Category.fetchOne(db, sql: "SELECT * FROM categories WHERE id = ?", arguments: [id])
                }
            }
        } catch {
            Logger.shared.error("upsert category failed", error: error)
            return nil
        }
    }

    func delete(id: Int64) {
        do {
            try db.write { db in
                // Soft delete
                try db.execute(sql: "UPDATE categories SET is_active = 0 WHERE id = ?", arguments: [id])
            }
        } catch {
            Logger.shared.error("delete category failed", error: error)
        }
    }
}
