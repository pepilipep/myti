import { app } from 'electron'
import { electronApp, optimizer } from '@electron-toolkit/utils'
import { createTray } from './tray'
import { startTimer } from './timer'
import { registerIpcHandlers } from './ipc-handlers'
import { getDb, closeDb } from './db/database'

// Prevent multiple instances
const gotLock = app.requestSingleInstanceLock()
if (!gotLock) {
  app.quit()
}

app.whenReady().then(() => {
  electronApp.setAppUserModelId('com.myti.app')

  app.on('browser-window-created', (_, window) => {
    optimizer.watchWindowShortcuts(window)
  })

  // Initialize database
  getDb()

  // Register IPC handlers
  registerIpcHandlers()

  // Create tray
  createTray()

  // Start the timer
  startTimer()

  // macOS: keep running when all windows closed (tray app)
  app.on('window-all-closed', () => {
    // Do nothing — keep running as tray app
  })
})

app.on('will-quit', () => {
  closeDb()
})
