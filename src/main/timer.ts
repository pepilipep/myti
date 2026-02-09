import { getAllSettings, setSetting } from './db/settings'
import { listCategories } from './db/categories'
import { showPopupWindow, getPopupWindow } from './windows'
import type { PopupData } from '@shared/types'

let intervalId: NodeJS.Timeout | null = null
let currentPromptedAt: string | null = null

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

  const intervalMs = settings.interval_minutes * 60 * 1000
  intervalId = setInterval(() => {
    tick()
  }, intervalMs)
}

export function stopTimer(): void {
  if (intervalId) {
    clearInterval(intervalId)
    intervalId = null
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

function tick(): void {
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

  // Send data once the window is ready
  popup.webContents.once('did-finish-load', () => {
    popup.webContents.send('popup:show', data)
  })
}
