import type { PopupData } from '@shared/types'
import { listCategories } from './db/categories'
import { getDb } from './db/database'
import { getAllSettings, setSetting } from './db/settings'
import { log } from './logger'

import { getPopupWindow, showPopupWindow } from './windows'

const POLL_INTERVAL_MS = 10_000
const NEXT_PROMPT_KEY = 'next_prompt_at'

let pollId: NodeJS.Timeout | null = null
let currentPromptedAt: string | null = null

function getNextPromptAt(): string | null {
  const db = getDb()
  const row = db.prepare('SELECT value FROM settings WHERE key = ?').get(NEXT_PROMPT_KEY) as
    | { value: string }
    | undefined
  return row?.value || null
}

export function setNextPromptAt(iso: string): void {
  setSetting(NEXT_PROMPT_KEY, iso)
}

function scheduleNext(): void {
  const settings = getAllSettings()
  const next = new Date(Date.now() + settings.interval_minutes * 60_000).toISOString()
  setNextPromptAt(next)
}

export function isTracking(): boolean {
  return getAllSettings().tracking_active
}

export function toggleTracking(): boolean {
  const current = isTracking()
  const next = !current
  setSetting('tracking_active', next ? '1' : '0')
  if (next) {
    startTimer()
  } else {
    stopTimer()
  }
  return next
}

export function startTimer(): void {
  stopTimer()
  const settings = getAllSettings()
  if (!settings.tracking_active) return

  // Initialize or fix stale next_prompt_at
  const stored = getNextPromptAt()
  if (!stored) {
    scheduleNext()
  } else {
    const staleThreshold = settings.interval_minutes * 60_000
    const msSinceNext = Date.now() - new Date(stored).getTime()
    if (msSinceNext > staleThreshold) {
      // Stale (e.g. next day) — reset rather than prompting immediately
      scheduleNext()
    }
  }

  pollId = setInterval(() => poll(), POLL_INTERVAL_MS)
}

export function stopTimer(): void {
  if (pollId) {
    clearInterval(pollId)
    pollId = null
  }
}

export function restartTimer(): void {
  if (isTracking()) {
    startTimer()
  }
}

export function getCurrentPromptedAt(): string | null {
  return currentPromptedAt
}

export function clearCurrentPromptedAt(): void {
  currentPromptedAt = null
}

function poll(): void {
  try {
    if (!isTracking()) return

    const nextStr = getNextPromptAt()
    if (!nextStr) {
      scheduleNext()
      return
    }

    const now = Date.now()
    if (now < new Date(nextStr).getTime()) return

    // Time to prompt — schedule the next one first
    scheduleNext()

    // Don't stack popups
    if (getPopupWindow()) return

    const categories = listCategories()
    if (categories.length === 0) return

    currentPromptedAt = new Date().toISOString()
    const popup = showPopupWindow()
    if (!popup) return

    const data: PopupData = {
      categories,
      promptedAt: currentPromptedAt
    }

    if (popup.webContents.isLoading()) {
      popup.webContents.once('did-finish-load', () => {
        popup.webContents.send('popup:show', data)
      })
    } else {
      popup.webContents.send('popup:show', data)
    }
  } catch (err) {
    log.error('Poll failed', err)
  }
}
