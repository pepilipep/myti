import { ipcMain, BrowserWindow } from 'electron'
import { createEntry } from './db/entries'
import { listCategories, upsertCategory, deleteCategory } from './db/categories'
import { getAllSettings, setSetting } from './db/settings'
import { getDayReport, getWeekReport, getAverageReport, getWeekTimeline } from './db/reports'
import { closePopupWindow, showMeetingPopupWindow, closeMeetingPopupWindow } from './windows'
import { toggleTracking, isTracking, restartTimer, clearCurrentPromptedAt, setNextPromptAt } from './timer'
import { updateMenu } from './tray'
import { getUpcomingBusyBlock } from './calendar'
import { createMeetingEntries } from './meeting-manager'
import { log } from './logger'
import type { BusyBlock, MeetingPopupData } from '@shared/types'

function handle(channel: string, handler: (...args: unknown[]) => unknown): void {
  ipcMain.handle(channel, async (_event, ...args) => {
    try {
      return await handler(...args)
    } catch (err) {
      log.error(`IPC ${channel} failed`, err)
      throw err
    }
  })
}

export function registerIpcHandlers(): void {
  handle('entry:submit', async (categoryId: number, promptedAt: string) => {
    const respondedAt = new Date().toISOString()
    const settings = getAllSettings()
    createEntry(categoryId, promptedAt, respondedAt, settings.interval_minutes)
    clearCurrentPromptedAt()
    closePopupWindow()

    // Check for upcoming meetings
    const block = await getUpcomingBusyBlock()
    if (block) {
      const start = new Date(block.start)
      const end = new Date(block.end)
      const fmt = (d: Date): string => d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
      const data: MeetingPopupData = {
        busyBlock: block,
        formattedTime: `${fmt(start)}\u2013${fmt(end)}`
      }
      const meetingWin = showMeetingPopupWindow()
      if (meetingWin) {
        if (meetingWin.webContents.isLoading()) {
          meetingWin.webContents.once('did-finish-load', () => {
            meetingWin.webContents.send('meeting-popup:show', data)
          })
        } else {
          meetingWin.webContents.send('meeting-popup:show', data)
        }
      }
    }
  })

  handle('categories:list', () => {
    return listCategories()
  })

  handle('categories:upsert', (category) => {
    return upsertCategory(category)
  })

  handle('categories:delete', (id: number) => {
    deleteCategory(id)
  })

  handle('report:day', (date: string) => {
    return getDayReport(date)
  })

  handle('report:week', (startDate: string) => {
    return getWeekReport(startDate)
  })

  handle('report:average', (startDate: string, endDate: string) => {
    return getAverageReport(startDate, endDate)
  })

  handle('report:weekTimeline', (startDate: string) => {
    return getWeekTimeline(startDate)
  })

  handle('settings:getAll', () => {
    return getAllSettings()
  })

  handle('settings:set', (key: string, value: string) => {
    setSetting(key, value)
    if (key === 'interval_minutes') {
      restartTimer()
    }
  })

  handle('tracking:toggle', () => {
    const active = toggleTracking()
    updateMenu()
    // Notify all renderer windows
    for (const win of BrowserWindow.getAllWindows()) {
      win.webContents.send('tracking:status-changed', active)
    }
    return active
  })

  handle('tracking:getStatus', () => {
    return isTracking()
  })

  handle('meeting:confirm', (block: BusyBlock) => {
    createMeetingEntries(block)
    setNextPromptAt(block.end)
    closeMeetingPopupWindow()
  })

  handle('meeting:decline', () => {
    closeMeetingPopupWindow()
  })
}
