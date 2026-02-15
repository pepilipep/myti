import { getDb } from './db/database'
import type { BusyBlock } from '@shared/types'
import { log } from './logger'

function findMeetingsCategoryId(): number | null {
  const db = getDb()
  const row = db.prepare("SELECT id FROM categories WHERE name = 'Meetings' AND is_active = 1").get() as
    | { id: number }
    | undefined
  return row?.id ?? null
}

export function createMeetingEntries(busyBlock: BusyBlock): void {
  const categoryId = findMeetingsCategoryId()
  if (!categoryId) {
    log.error('No active "Meetings" category found — skipping meeting entries')
    return
  }

  const db = getDb()
  const startMs = new Date(busyBlock.start).getTime()
  const endMs = new Date(busyBlock.end).getTime()
  const durationMinutes = Math.round((endMs - startMs) / 60_000)

  db.prepare(
    `INSERT INTO entries (category_id, prompted_at, responded_at, credited_minutes)
     VALUES (?, ?, ?, ?)`
  ).run(categoryId, busyBlock.start, busyBlock.start, durationMinutes)
}
