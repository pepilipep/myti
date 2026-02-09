import { contextBridge, ipcRenderer } from 'electron'
import type { ElectronAPI, PopupData } from '@shared/types'

const api: ElectronAPI = {
  entrySubmit: (categoryId, promptedAt) => ipcRenderer.invoke('entry:submit', categoryId, promptedAt),

  categoriesList: () => ipcRenderer.invoke('categories:list'),
  categoriesUpsert: (category) => ipcRenderer.invoke('categories:upsert', category),
  categoriesDelete: (id) => ipcRenderer.invoke('categories:delete', id),

  reportDay: (date) => ipcRenderer.invoke('report:day', date),
  reportWeek: (startDate) => ipcRenderer.invoke('report:week', startDate),
  reportAverage: (startDate, endDate) => ipcRenderer.invoke('report:average', startDate, endDate),

  settingsGetAll: () => ipcRenderer.invoke('settings:getAll'),
  settingsSet: (key, value) => ipcRenderer.invoke('settings:set', key, value),

  trackingToggle: () => ipcRenderer.invoke('tracking:toggle'),
  trackingGetStatus: () => ipcRenderer.invoke('tracking:getStatus'),

  onPopupShow: (callback: (data: PopupData) => void) => {
    const handler = (_event: Electron.IpcRendererEvent, data: PopupData): void => callback(data)
    ipcRenderer.on('popup:show', handler)
    return () => ipcRenderer.removeListener('popup:show', handler)
  },

  onTrackingStatusChanged: (callback: (active: boolean) => void) => {
    const handler = (_event: Electron.IpcRendererEvent, active: boolean): void => callback(active)
    ipcRenderer.on('tracking:status-changed', handler)
    return () => ipcRenderer.removeListener('tracking:status-changed', handler)
  }
}

contextBridge.exposeInMainWorld('api', api)
