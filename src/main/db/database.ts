import Database from 'better-sqlite3'
import { app } from 'electron'
import path from 'path'
import fs from 'fs'

let db: Database.Database

export function getDb(): Database.Database {
  if (!db) {
    const userDataPath = app.getPath('userData')
    fs.mkdirSync(userDataPath, { recursive: true })
    const dbPath = path.join(userDataPath, 'myti.db')
    db = new Database(dbPath)
    db.pragma('journal_mode = WAL')
    db.pragma('foreign_keys = ON')
    migrate(db)
  }
  return db
}

function migrate(db: Database.Database): void {
  db.exec(`
    CREATE TABLE IF NOT EXISTS categories (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      name        TEXT NOT NULL,
      color       TEXT NOT NULL DEFAULT '#3B82F6',
      sort_order  INTEGER NOT NULL DEFAULT 0,
      is_active   INTEGER NOT NULL DEFAULT 1,
      created_at  TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS entries (
      id               INTEGER PRIMARY KEY AUTOINCREMENT,
      category_id      INTEGER NOT NULL REFERENCES categories(id),
      prompted_at      TEXT NOT NULL,
      responded_at     TEXT NOT NULL,
      credited_minutes REAL NOT NULL,
      is_afk           INTEGER NOT NULL DEFAULT 0,
      created_at       TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS settings (
      key   TEXT PRIMARY KEY,
      value TEXT NOT NULL
    );
  `)

  // Seed defaults
  const catCount = db.prepare('SELECT COUNT(*) as c FROM categories').get() as { c: number }
  if (catCount.c === 0) {
    const insert = db.prepare('INSERT INTO categories (name, color, sort_order) VALUES (?, ?, ?)')
    const defaults = [
      ['Coding', '#3B82F6', 0],
      ['Code Review', '#8B5CF6', 1],
      ['Meetings', '#F59E0B', 2],
      ['Planning', '#10B981', 3],
      ['Debugging', '#EF4444', 4],
      ['Documentation', '#6366F1', 5],
      ['Slack / Email', '#EC4899', 6],
      ['Learning', '#14B8A6', 7],
      ['Break', '#6B7280', 8]
    ]
    const insertMany = db.transaction((cats: (string | number)[][]) => {
      for (const cat of cats) insert.run(...cat)
    })
    insertMany(defaults)
  }

  const settingsCount = db.prepare('SELECT COUNT(*) as c FROM settings').get() as { c: number }
  if (settingsCount.c === 0) {
    const insert = db.prepare('INSERT OR IGNORE INTO settings (key, value) VALUES (?, ?)')
    insert.run('interval_minutes', '20')
    insert.run('afk_threshold_minutes', '20')
    insert.run('tracking_active', '1')
  }
}

export function closeDb(): void {
  if (db) {
    db.close()
  }
}
