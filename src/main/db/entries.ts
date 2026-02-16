import { getDb } from './database'

export function createEntry(
  categoryId: number,
  promptedAt: string,
  respondedAt: string,
  creditedMinutes: number
): void {
  const db = getDb()

  db.prepare(
    `INSERT INTO entries (category_id, prompted_at, responded_at, credited_minutes)
     VALUES (?, ?, ?, ?)`
  ).run(categoryId, promptedAt, respondedAt, creditedMinutes)
}
