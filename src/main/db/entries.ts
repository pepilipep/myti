import { getDb } from './database'
import { getAllSettings } from './settings'

export function createEntry(categoryId: number, promptedAt: string, respondedAt: string): void {
  const db = getDb()
  const settings = getAllSettings()
  const creditedMinutes = settings.interval_minutes

  db.prepare(
    `INSERT INTO entries (category_id, prompted_at, responded_at, credited_minutes)
     VALUES (?, ?, ?, ?)`
  ).run(categoryId, promptedAt, respondedAt, creditedMinutes)
}
