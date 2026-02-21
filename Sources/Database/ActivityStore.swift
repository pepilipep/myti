import GRDB
import Foundation

final class ActivityStore {
    static let shared = ActivityStore()
    private init() {}

    private var db: DatabaseQueue {
        DatabaseManager.shared.dbQueue!
    }

    /// Returns active activities ordered by usage count (most-used first).
    func listByUsage() -> [Activity] {
        do {
            return try db.read { db in
                try Activity.fetchAll(db, sql: """
                    SELECT a.*
                    FROM activities a
                    LEFT JOIN entries e ON e.activity_id = a.id
                    WHERE a.is_active = 1
                    GROUP BY a.id
                    ORDER BY COUNT(e.id) DESC, a.name ASC
                """)
            }
        } catch {
            Logger.shared.error("listByUsage failed", error: error)
            return []
        }
    }

    /// Finds an existing activity by name (case-insensitive) or creates a new one without a category.
    func findOrCreate(name: String) -> Activity? {
        do {
            return try db.write { db in
                if let existing = try Activity.fetchOne(db, sql: """
                    SELECT * FROM activities WHERE LOWER(name) = LOWER(?) AND is_active = 1
                """, arguments: [name]) {
                    return existing
                }

                try db.execute(
                    sql: "INSERT INTO activities (name) VALUES (?)",
                    arguments: [name]
                )
                let id = db.lastInsertedRowID
                return try Activity.fetchOne(db, sql: "SELECT * FROM activities WHERE id = ?", arguments: [id])
            }
        } catch {
            Logger.shared.error("findOrCreate activity failed", error: error)
            return nil
        }
    }

    /// Updates an activity's category.
    func updateCategory(activityId: Int64, categoryId: Int64?) {
        do {
            try db.write { db in
                try db.execute(
                    sql: "UPDATE activities SET category_id = ? WHERE id = ?",
                    arguments: [categoryId, activityId]
                )
            }
        } catch {
            Logger.shared.error("updateCategory failed", error: error)
        }
    }

    /// Updates an activity's name.
    func rename(activityId: Int64, name: String) {
        do {
            try db.write { db in
                try db.execute(
                    sql: "UPDATE activities SET name = ? WHERE id = ?",
                    arguments: [name, activityId]
                )
            }
        } catch {
            Logger.shared.error("rename activity failed", error: error)
        }
    }

    /// Soft-deletes an activity.
    func delete(id: Int64) {
        do {
            try db.write { db in
                try db.execute(
                    sql: "UPDATE activities SET is_active = 0 WHERE id = ?",
                    arguments: [id]
                )
            }
        } catch {
            Logger.shared.error("delete activity failed", error: error)
        }
    }

    /// Finds an existing activity by name and category, or creates one.
    func findOrCreate(name: String, categoryId: Int64) -> Activity? {
        do {
            return try db.write { db in
                if let existing = try Activity.fetchOne(db, sql: """
                    SELECT * FROM activities WHERE LOWER(name) = LOWER(?) AND category_id = ? AND is_active = 1
                """, arguments: [name, categoryId]) {
                    return existing
                }

                try db.execute(
                    sql: "INSERT INTO activities (name, category_id) VALUES (?, ?)",
                    arguments: [name, categoryId]
                )
                let id = db.lastInsertedRowID
                return try Activity.fetchOne(db, sql: "SELECT * FROM activities WHERE id = ?", arguments: [id])
            }
        } catch {
            Logger.shared.error("findOrCreate activity with category failed", error: error)
            return nil
        }
    }
}
