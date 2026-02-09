import { getDb } from './database'
import type { Settings } from '@shared/types'

export function getAllSettings(): Settings {
  const db = getDb()
  const rows = db.prepare('SELECT key, value FROM settings').all() as { key: string; value: string }[]
  const map: Record<string, string> = {}
  for (const row of rows) map[row.key] = row.value
  return {
    interval_minutes: parseInt(map.interval_minutes ?? '20', 10),
    afk_threshold_minutes: parseInt(map.afk_threshold_minutes ?? '20', 10),
    tracking_active: (map.tracking_active ?? '1') === '1'
  }
}

export function setSetting(key: string, value: string): void {
  const db = getDb()
  db.prepare('INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)').run(key, value)
}
