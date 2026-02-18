import GRDB
import Foundation

final class EntryStore {
    static let shared = EntryStore()
    private init() {}

    private var db: DatabaseQueue {
        DatabaseManager.shared.dbQueue!
    }

    func createEntry(categoryId: Int64, promptedAt: String, respondedAt: String, creditedMinutes: Double) {
        do {
            try db.write { db in
                try db.execute(
                    sql: """
                        INSERT INTO entries (category_id, prompted_at, responded_at, credited_minutes)
                        VALUES (?, ?, ?, ?)
                    """,
                    arguments: [categoryId, promptedAt, respondedAt, creditedMinutes]
                )
            }
        } catch {
            Logger.shared.error("createEntry failed", error: error)
        }
    }
}
