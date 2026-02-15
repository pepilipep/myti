import { Tray, Menu, nativeImage } from 'electron'
import { is } from '@electron-toolkit/utils'
import path from 'path'
import { showReportsWindow, showSettingsWindow } from './windows'
import { toggleTracking, isTracking } from './timer'

let tray: Tray | null = null

export function createTray(): Tray {
  const iconPath = path.join(__dirname, '../../resources/trayTemplate.png')
  let icon: nativeImage
  try {
    icon = nativeImage.createFromPath(iconPath)
    icon.setTemplateImage(true)
  } catch {
    // Fallback: create a simple 16x16 icon
    icon = nativeImage.createEmpty()
  }

  tray = new Tray(icon)
  tray.setToolTip(is.dev ? 'myti (dev)' : 'myti')
  if (is.dev) {
    tray.setTitle('Dev')
  }
  updateMenu()
  return tray
}

export function updateMenu(): void {
  if (!tray) return
  const tracking = isTracking()
  const menu = Menu.buildFromTemplate([
    {
      label: tracking ? 'Pause Tracking' : 'Start Tracking',
      click: () => {
        toggleTracking()
        updateMenu()
      }
    },
    { type: 'separator' },
    {
      label: 'Open Reports',
      click: () => showReportsWindow()
    },
    {
      label: 'Settings',
      click: () => showSettingsWindow()
    },
    { type: 'separator' },
    {
      label: 'Quit',
      role: 'quit'
    }
  ])
  tray.setContextMenu(menu)
}
