import { app } from 'electron'
import { electronApp, optimizer, is } from '@electron-toolkit/utils'
import { createTray } from './tray'
import { startTimer } from './timer'
import { registerIpcHandlers } from './ipc-handlers'
import { getDb, closeDb } from './db/database'
import { initLogger, log } from './logger'

// Separate dev and prod so they can run simultaneously
if (is.dev) {
  app.setName('myti-dev')
}

// Prevent multiple instances
const gotLock = app.requestSingleInstanceLock()
if (!gotLock) {
  app.quit()
}

// Init logger early (after app name is set so userData path is correct)
initLogger()
log.info('App starting')

process.on('uncaughtException', (err) => {
  log.error('Uncaught exception', err)
})

process.on('unhandledRejection', (reason) => {
  log.error('Unhandled rejection', reason instanceof Error ? reason : new Error(String(reason)))
})

app.whenReady().then(() => {
  electronApp.setAppUserModelId('com.myti.app')

  app.on('browser-window-created', (_, window) => {
    optimizer.watchWindowShortcuts(window)
  })

  // Initialize database
  getDb()
  log.info('Database initialized')

  // Register IPC handlers
  registerIpcHandlers()

  // Create tray
  createTray()
  log.info('Tray created')

  // Start the timer
  startTimer()
  log.info('Timer started')

  // macOS: keep running when all windows closed (tray app)
  app.on('window-all-closed', () => {
    // Do nothing — keep running as tray app
  })
})

app.on('will-quit', () => {
  log.info('App quitting')
  closeDb()
})
