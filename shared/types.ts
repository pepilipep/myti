export interface Category {
  id: number
  name: string
  color: string
  sort_order: number
  is_active: boolean
}

export interface Entry {
  id: number
  category_id: number
  prompted_at: string
  responded_at: string
  credited_minutes: number
}

export interface Settings {
  interval_minutes: number
  tracking_active: boolean
}

export interface DayReport {
  date: string
  entries: DayReportEntry[]
  total_minutes: number
}

export interface DayReportEntry {
  category_id: number
  category_name: string
  color: string
  total_minutes: number
  entry_count: number
}

export interface WeekReport {
  start_date: string
  end_date: string
  days: DayReport[]
  totals: DayReportEntry[]
  total_minutes: number
}

export interface TimelineEntry {
  prompted_at: string
  credited_minutes: number
  category_name: string
  color: string
}

export interface DayTimeline {
  date: string
  entries: TimelineEntry[]
  total_minutes: number
}

export interface WeekTimeline {
  start_date: string
  end_date: string
  days: DayTimeline[]
}

export interface BusyBlock {
  start: string
  end: string
  title: string
}

export interface MeetingPopupData {
  busyBlock: BusyBlock
  formattedTime: string
}

export interface PopupData {
  categories: Category[]
  promptedAt: string
}

export interface ElectronAPI {
  entrySubmit: (categoryId: number, promptedAt: string) => Promise<void>
  categoriesList: () => Promise<Category[]>
  categoriesUpsert: (category: Partial<Category> & { name: string; color: string }) => Promise<Category>
  categoriesDelete: (id: number) => Promise<void>
  reportDay: (date: string) => Promise<DayReport>
  reportWeek: (startDate: string) => Promise<WeekReport>
  reportAverage: (startDate: string, endDate: string) => Promise<DayReportEntry[]>
  reportWeekTimeline: (startDate: string) => Promise<WeekTimeline>
  settingsGetAll: () => Promise<Settings>
  settingsSet: (key: string, value: string) => Promise<void>
  trackingToggle: () => Promise<boolean>
  trackingGetStatus: () => Promise<boolean>
  onPopupShow: (callback: (data: PopupData) => void) => () => void
  onTrackingStatusChanged: (callback: (active: boolean) => void) => () => void
  meetingConfirm: (block: BusyBlock) => Promise<void>
  meetingDecline: () => Promise<void>
  onMeetingPopupShow: (callback: (data: MeetingPopupData) => void) => () => void
}

declare global {
  interface Window {
    api: ElectronAPI
  }
}
