import GRDB
import Foundation

final class EntryStore {
    static let shared = EntryStore()
    private init() {}

    private var db: DatabaseQueue {
        DatabaseManager.shared.dbQueue!
    }

    func deleteEntry(id: Int64) {
        do {
            try db.write { db in
                try db.execute(sql: "DELETE FROM entries WHERE id = ?", arguments: [id])
            }
        } catch {
            Logger.shared.error("deleteEntry failed", error: error)
        }
    }

    func createEntry(activityId: Int64, promptedAt: String, respondedAt: String, creditedMinutes: Double) {
        do {
            try db.write { db in
                try db.execute(
                    sql: """
                        INSERT INTO entries (activity_id, prompted_at, responded_at, credited_minutes)
                        VALUES (?, ?, ?, ?)
                    """,
                    arguments: [activityId, promptedAt, respondedAt, creditedMinutes]
                )
            }
        } catch {
            Logger.shared.error("createEntry failed", error: error)
        }
    }
}
