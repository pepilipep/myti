import { BrowserWindow, screen, shell } from 'electron'
import { join } from 'path'
import { is } from '@electron-toolkit/utils'

let popupWindow: BrowserWindow | null = null
let meetingPopupWindow: BrowserWindow | null = null
let reportsWindow: BrowserWindow | null = null
let settingsWindow: BrowserWindow | null = null

function getRendererUrl(hash: string): string {
  if (is.dev && process.env['ELECTRON_RENDERER_URL']) {
    return `${process.env['ELECTRON_RENDERER_URL']}#${hash}`
  }
  return `file://${join(__dirname, '../renderer/index.html')}#${hash}`
}

export function showPopupWindow(): BrowserWindow | null {
  if (popupWindow && !popupWindow.isDestroyed()) {
    popupWindow.focus()
    return popupWindow
  }

  const { width, height } = screen.getPrimaryDisplay().workAreaSize
  popupWindow = new BrowserWindow({
    type: 'panel',
    width: 320,
    height: 260,
    x: Math.round((width - 320) / 2),
    y: Math.round((height - 260) / 2),
    frame: false,
    resizable: false,
    alwaysOnTop: true,
    skipTaskbar: true,
    show: false,
    webPreferences: {
      preload: join(__dirname, '../preload/index.js'),
      sandbox: false
    }
  })

  popupWindow.setVisibleOnAllWorkspaces(true, { visibleOnFullScreen: true })
  popupWindow.setAlwaysOnTop(true, 'pop-up-menu')
  popupWindow.loadURL(getRendererUrl('/popup'))
  popupWindow.once('ready-to-show', () => {
    popupWindow?.show()
  })
  popupWindow.on('closed', () => {
    popupWindow = null
  })

  return popupWindow
}

export function closePopupWindow(): void {
  if (popupWindow && !popupWindow.isDestroyed()) {
    popupWindow.close()
    popupWindow = null
  }
}

export function getPopupWindow(): BrowserWindow | null {
  return popupWindow && !popupWindow.isDestroyed() ? popupWindow : null
}

export function showMeetingPopupWindow(): BrowserWindow | null {
  if (meetingPopupWindow && !meetingPopupWindow.isDestroyed()) {
    meetingPopupWindow.focus()
    return meetingPopupWindow
  }

  const { width, height } = screen.getPrimaryDisplay().workAreaSize
  meetingPopupWindow = new BrowserWindow({
    type: 'panel',
    width: 320,
    height: 160,
    x: Math.round((width - 320) / 2),
    y: Math.round((height - 160) / 2),
    frame: false,
    resizable: false,
    alwaysOnTop: true,
    skipTaskbar: true,
    show: false,
    webPreferences: {
      preload: join(__dirname, '../preload/index.js'),
      sandbox: false
    }
  })

  meetingPopupWindow.setVisibleOnAllWorkspaces(true, { visibleOnFullScreen: true })
  meetingPopupWindow.setAlwaysOnTop(true, 'pop-up-menu')
  meetingPopupWindow.loadURL(getRendererUrl('/meeting-confirm'))
  meetingPopupWindow.once('ready-to-show', () => {
    meetingPopupWindow?.show()
  })
  meetingPopupWindow.on('closed', () => {
    meetingPopupWindow = null
  })

  return meetingPopupWindow
}

export function closeMeetingPopupWindow(): void {
  if (meetingPopupWindow && !meetingPopupWindow.isDestroyed()) {
    meetingPopupWindow.close()
    meetingPopupWindow = null
  }
}

export function getMeetingPopupWindow(): BrowserWindow | null {
  return meetingPopupWindow && !meetingPopupWindow.isDestroyed() ? meetingPopupWindow : null
}

export function showReportsWindow(): void {
  if (reportsWindow && !reportsWindow.isDestroyed()) {
    reportsWindow.setAlwaysOnTop(true, 'floating')
    reportsWindow.show()
    reportsWindow.focus()
    reportsWindow.setAlwaysOnTop(false)
    return
  }

  reportsWindow = new BrowserWindow({
    type: 'panel',
    width: 800,
    height: 600,
    skipTaskbar: true,
    show: false,
    webPreferences: {
      preload: join(__dirname, '../preload/index.js'),
      sandbox: false
    }
  })

  reportsWindow.loadURL(getRendererUrl('/reports'))
  reportsWindow.once('ready-to-show', () => {
    reportsWindow?.setAlwaysOnTop(true, 'floating')
    reportsWindow?.show()
    reportsWindow?.focus()
    reportsWindow?.setAlwaysOnTop(false)
  })
  reportsWindow.on('closed', () => {
    reportsWindow = null
  })
  reportsWindow.webContents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url)
    return { action: 'deny' }
  })
}

export function showSettingsWindow(): void {
  if (settingsWindow && !settingsWindow.isDestroyed()) {
    settingsWindow.setAlwaysOnTop(true, 'floating')
    settingsWindow.show()
    settingsWindow.focus()
    settingsWindow.setAlwaysOnTop(false)
    return
  }

  settingsWindow = new BrowserWindow({
    type: 'panel',
    width: 500,
    height: 400,
    skipTaskbar: true,
    show: false,
    webPreferences: {
      preload: join(__dirname, '../preload/index.js'),
      sandbox: false
    }
  })

  settingsWindow.loadURL(getRendererUrl('/settings'))
  settingsWindow.once('ready-to-show', () => {
    settingsWindow?.setAlwaysOnTop(true, 'floating')
    settingsWindow?.show()
    settingsWindow?.focus()
    settingsWindow?.setAlwaysOnTop(false)
  })
  settingsWindow.on('closed', () => {
    settingsWindow = null
  })
}
