import { BrowserWindow, screen, shell } from 'electron'
import { join } from 'path'
import { is } from '@electron-toolkit/utils'

let popupWindow: BrowserWindow | null = null
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

  popupWindow.setVisibleOnAllWorkspaces(true)
  popupWindow.loadURL(getRendererUrl('/popup'))
  popupWindow.once('ready-to-show', () => popupWindow?.show())
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

export function showReportsWindow(): void {
  if (reportsWindow && !reportsWindow.isDestroyed()) {
    reportsWindow.focus()
    return
  }

  reportsWindow = new BrowserWindow({
    width: 800,
    height: 600,
    show: false,
    webPreferences: {
      preload: join(__dirname, '../preload/index.js'),
      sandbox: false
    }
  })

  reportsWindow.loadURL(getRendererUrl('/reports'))
  reportsWindow.once('ready-to-show', () => reportsWindow?.show())
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
    settingsWindow.focus()
    return
  }

  settingsWindow = new BrowserWindow({
    width: 500,
    height: 400,
    show: false,
    webPreferences: {
      preload: join(__dirname, '../preload/index.js'),
      sandbox: false
    }
  })

  settingsWindow.loadURL(getRendererUrl('/settings'))
  settingsWindow.once('ready-to-show', () => settingsWindow?.show())
  settingsWindow.on('closed', () => {
    settingsWindow = null
  })
}
