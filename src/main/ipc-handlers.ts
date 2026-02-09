import { ipcMain, BrowserWindow } from 'electron'
import { createEntry } from './db/entries'
import { listCategories, upsertCategory, deleteCategory } from './db/categories'
import { getAllSettings, setSetting } from './db/settings'
import { getDayReport, getWeekReport, getAverageReport } from './db/reports'
import { closePopupWindow } from './windows'
import { toggleTracking, isTracking, restartTimer, clearCurrentPromptedAt } from './timer'
import { updateMenu } from './tray'

export function registerIpcHandlers(): void {
  ipcMain.handle('entry:submit', (_event, categoryId: number, promptedAt: string) => {
    const respondedAt = new Date().toISOString()
    createEntry(categoryId, promptedAt, respondedAt)
    clearCurrentPromptedAt()
    closePopupWindow()
  })

  ipcMain.handle('categories:list', () => {
    return listCategories()
  })

  ipcMain.handle('categories:upsert', (_event, category) => {
    return upsertCategory(category)
  })

  ipcMain.handle('categories:delete', (_event, id: number) => {
    deleteCategory(id)
  })

  ipcMain.handle('report:day', (_event, date: string) => {
    return getDayReport(date)
  })

  ipcMain.handle('report:week', (_event, startDate: string) => {
    return getWeekReport(startDate)
  })

  ipcMain.handle('report:average', (_event, startDate: string, endDate: string) => {
    return getAverageReport(startDate, endDate)
  })

  ipcMain.handle('settings:getAll', () => {
    return getAllSettings()
  })

  ipcMain.handle('settings:set', (_event, key: string, value: string) => {
    setSetting(key, value)
    if (key === 'interval_minutes') {
      restartTimer()
    }
  })

  ipcMain.handle('tracking:toggle', () => {
    const active = toggleTracking()
    updateMenu()
    // Notify all renderer windows
    for (const win of BrowserWindow.getAllWindows()) {
      win.webContents.send('tracking:status-changed', active)
    }
    return active
  })

  ipcMain.handle('tracking:getStatus', () => {
    return isTracking()
  })
}
