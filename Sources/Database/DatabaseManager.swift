import GRDB
import Foundation

final class DatabaseManager {
    static let shared = DatabaseManager()

    private(set) var dbQueue: DatabaseQueue?

    private init() {}

    var dbPath: String {
        #if DEBUG
        let appName = "myti-dev"
        #else
        let appName = "myti"
        #endif
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent(appName)
        return dir.appendingPathComponent("myti.db").path
    }

    func setup() throws {
        let path = dbPath
        let dir = (path as NSString).deletingLastPathComponent
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)

        var config = Configuration()
        config.foreignKeysEnabled = true

        dbQueue = try DatabaseQueue(path: path, configuration: config)

        try dbQueue!.write { db in
            // WAL mode
            try db.execute(sql: "PRAGMA journal_mode = WAL")

            // Create tables
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS categories (
                    id          INTEGER PRIMARY KEY AUTOINCREMENT,
                    name        TEXT NOT NULL,
                    color       TEXT NOT NULL DEFAULT '#3B82F6',
                    sort_order  INTEGER NOT NULL DEFAULT 0,
                    is_active   INTEGER NOT NULL DEFAULT 1,
                    created_at  TEXT NOT NULL DEFAULT (datetime('now'))
                );

                CREATE TABLE IF NOT EXISTS activities (
                    id          INTEGER PRIMARY KEY AUTOINCREMENT,
                    name        TEXT NOT NULL,
                    category_id INTEGER REFERENCES categories(id),
                    is_active   INTEGER NOT NULL DEFAULT 1,
                    created_at  TEXT NOT NULL DEFAULT (datetime('now'))
                );

                CREATE TABLE IF NOT EXISTS settings (
                    key   TEXT PRIMARY KEY,
                    value TEXT NOT NULL
                );
            """)

            // Seed default categories if empty
            let catCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM categories") ?? 0
            if catCount == 0 {
                let defaults: [(String, String, Int)] = [
                    ("Coding", "#3B82F6", 0),
                    ("Code Review", "#8B5CF6", 1),
                    ("Meetings", "#F59E0B", 2),
                    ("Planning", "#10B981", 3),
                    ("Debugging", "#EF4444", 4),
                    ("Documentation", "#6366F1", 5),
                    ("Slack / Email", "#EC4899", 6),
                    ("Learning", "#14B8A6", 7),
                    ("Break", "#6B7280", 8)
                ]
                for (name, color, order) in defaults {
                    try db.execute(
                        sql: "INSERT INTO categories (name, color, sort_order) VALUES (?, ?, ?)",
                        arguments: [name, color, order]
                    )
                }
            }

            // Seed default settings if empty
            let settingsCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM settings") ?? 0
            if settingsCount == 0 {
                try db.execute(sql: "INSERT OR IGNORE INTO settings (key, value) VALUES (?, ?)",
                               arguments: ["interval_minutes", "20"])
                try db.execute(sql: "INSERT OR IGNORE INTO settings (key, value) VALUES (?, ?)",
                               arguments: ["tracking_active", "1"])
            }

            // Migration v1: entries table gets activity_id instead of category_id
            let version = try Int.fetchOne(db, sql: "PRAGMA user_version") ?? 0
            if version < 1 {
                // Check if old entries table has category_id column (pre-migration)
                let hasOldEntries = try Bool.fetchOne(db, sql: """
                    SELECT COUNT(*) > 0 FROM sqlite_master
                    WHERE type = 'table' AND name = 'entries'
                    AND sql LIKE '%category_id%'
                """) ?? false

                if hasOldEntries {
                    // Create "unspecified" activity for each existing category
                    try db.execute(sql: """
                        INSERT INTO activities (name, category_id)
                        SELECT 'unspecified', id FROM categories
                    """)

                    // Recreate entries table with activity_id
                    try db.execute(sql: """
                        CREATE TABLE entries_new (
                            id               INTEGER PRIMARY KEY AUTOINCREMENT,
                            activity_id      INTEGER NOT NULL REFERENCES activities(id),
                            prompted_at      TEXT NOT NULL,
                            responded_at     TEXT NOT NULL,
                            credited_minutes REAL NOT NULL,
                            created_at       TEXT NOT NULL DEFAULT (datetime('now'))
                        )
                    """)

                    // Migrate entries: map category_id -> matching "unspecified" activity
                    try db.execute(sql: """
                        INSERT INTO entries_new (id, activity_id, prompted_at, responded_at, credited_minutes, created_at)
                        SELECT e.id, a.id, e.prompted_at, e.responded_at, e.credited_minutes, e.created_at
                        FROM entries e
                        JOIN activities a ON a.category_id = e.category_id AND a.name = 'unspecified'
                    """)

                    try db.execute(sql: "DROP TABLE entries")
                    try db.execute(sql: "ALTER TABLE entries_new RENAME TO entries")
                } else {
                    // Fresh install or already migrated — create entries table with activity_id
                    try db.execute(sql: """
                        CREATE TABLE IF NOT EXISTS entries (
                            id               INTEGER PRIMARY KEY AUTOINCREMENT,
                            activity_id      INTEGER NOT NULL REFERENCES activities(id),
                            prompted_at      TEXT NOT NULL,
                            responded_at     TEXT NOT NULL,
                            credited_minutes REAL NOT NULL,
                            created_at       TEXT NOT NULL DEFAULT (datetime('now'))
                        )
                    """)
                }

                try db.execute(sql: "PRAGMA user_version = 1")
            }
        }

        Logger.shared.info("Database opened at \(path)")
    }

    func close() {
        dbQueue = nil
    }
}
