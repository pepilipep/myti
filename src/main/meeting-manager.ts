import { getDb } from './db/database'
import { setSetting } from './db/settings'
import type { BusyBlock } from '@shared/types'
import { log } from './logger'

const BUSY_UNTIL_KEY = 'busy_until'

export function getBusyUntil(): string | null {
  const db = getDb()
  const row = db.prepare('SELECT value FROM settings WHERE key = ?').get(BUSY_UNTIL_KEY) as
    | { value: string }
    | undefined
  return row?.value || null
}

export function setBusyUntil(ts: string): void {
  setSetting(BUSY_UNTIL_KEY, ts)
}

export function clearBusyUntil(): void {
  const db = getDb()
  db.prepare('DELETE FROM settings WHERE key = ?').run(BUSY_UNTIL_KEY)
}

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
