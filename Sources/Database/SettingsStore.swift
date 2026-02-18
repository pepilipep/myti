import GRDB
import Foundation

final class SettingsStore {
    static let shared = SettingsStore()
    private init() {}

    private var db: DatabaseQueue {
        DatabaseManager.shared.dbQueue!
    }

    func getAll() -> AppSettings {
        do {
            return try db.read { db in
                let rows = try Row.fetchAll(db, sql: "SELECT key, value FROM settings")
                var map: [String: String] = [:]
                for row in rows {
                    map[row["key"] as String] = row["value"] as String
                }
                return AppSettings(
                    intervalMinutes: Int(map["interval_minutes"] ?? "20") ?? 20,
                    trackingActive: (map["tracking_active"] ?? "1") == "1"
                )
            }
        } catch {
            Logger.shared.error("getAll settings failed", error: error)
            return AppSettings(intervalMinutes: 20, trackingActive: true)
        }
    }

    func set(key: String, value: String) {
        do {
            try db.write { db in
                try db.execute(
                    sql: "INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)",
                    arguments: [key, value]
                )
            }
        } catch {
            Logger.shared.error("set setting failed", error: error)
        }
    }

    func isTrackingActive() -> Bool {
        getAll().trackingActive
    }

    func getNextPromptAt() -> String? {
        do {
            return try db.read { db in
                try String.fetchOne(db, sql: "SELECT value FROM settings WHERE key = ?", arguments: ["next_prompt_at"])
            }
        } catch {
            return nil
        }
    }

    func setNextPromptAt(_ iso: String) {
        set(key: "next_prompt_at", value: iso)
    }
}
