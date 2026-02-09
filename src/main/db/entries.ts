import { getDb } from './database'
import { getAllSettings } from './settings'

export function createEntry(categoryId: number, promptedAt: string, respondedAt: string): void {
  const db = getDb()
  const settings = getAllSettings()
  const promptTime = new Date(promptedAt).getTime()
  const respondTime = new Date(respondedAt).getTime()
  const delayMinutes = (respondTime - promptTime) / 60000
  const isAfk = delayMinutes > settings.afk_threshold_minutes
  const creditedMinutes = settings.interval_minutes

  db.prepare(
    `INSERT INTO entries (category_id, prompted_at, responded_at, credited_minutes, is_afk)
     VALUES (?, ?, ?, ?, ?)`
  ).run(categoryId, promptedAt, respondedAt, creditedMinutes, isAfk ? 1 : 0)
}
