import { getDb } from './database'
import type { DayReport, DayReportEntry, WeekReport } from '@shared/types'

interface DayReportRow {
  category_id: number
  category_name: string
  color: string
  total_minutes: number
  entry_count: number
}

export function getDayReport(date: string): DayReport {
  const db = getDb()
  const rows = db
    .prepare(
      `
    SELECT
      e.category_id,
      c.name as category_name,
      c.color,
      SUM(e.credited_minutes) as total_minutes,
      COUNT(*) as entry_count
    FROM entries e
    JOIN categories c ON c.id = e.category_id
    WHERE date(e.prompted_at) = date(?)
    GROUP BY e.category_id
    ORDER BY total_minutes DESC
  `
    )
    .all(date) as DayReportRow[]

  const entries: DayReportEntry[] = rows.map((r) => ({
    category_id: r.category_id,
    category_name: r.category_name,
    color: r.color,
    total_minutes: r.total_minutes,
    entry_count: r.entry_count
  }))

  return {
    date,
    entries,
    total_minutes: entries.reduce((s, e) => s + e.total_minutes, 0)
  }
}

export function getWeekReport(startDate: string): WeekReport {
  const start = new Date(startDate)
  // Adjust to Monday
  const day = start.getDay()
  const diff = day === 0 ? -6 : 1 - day
  start.setDate(start.getDate() + diff)

  const days: DayReport[] = []
  for (let i = 0; i < 7; i++) {
    const d = new Date(start)
    d.setDate(d.getDate() + i)
    const dateStr = d.toISOString().split('T')[0]
    days.push(getDayReport(dateStr))
  }

  const end = new Date(start)
  end.setDate(end.getDate() + 6)

  // Aggregate totals across the week
  const totalsMap = new Map<number, DayReportEntry>()
  for (const day of days) {
    for (const entry of day.entries) {
      const existing = totalsMap.get(entry.category_id)
      if (existing) {
        existing.total_minutes += entry.total_minutes
        existing.entry_count += entry.entry_count
      } else {
        totalsMap.set(entry.category_id, { ...entry })
      }
    }
  }

  const totals = Array.from(totalsMap.values()).sort((a, b) => b.total_minutes - a.total_minutes)

  return {
    start_date: start.toISOString().split('T')[0],
    end_date: end.toISOString().split('T')[0],
    days,
    totals,
    total_minutes: totals.reduce((s, e) => s + e.total_minutes, 0)
  }
}

export function getAverageReport(startDate: string, endDate: string): DayReportEntry[] {
  const db = getDb()
  const rows = db
    .prepare(
      `
    SELECT
      e.category_id,
      c.name as category_name,
      c.color,
      SUM(e.credited_minutes) as total_minutes,
      COUNT(*) as entry_count
    FROM entries e
    JOIN categories c ON c.id = e.category_id
    WHERE date(e.prompted_at) BETWEEN date(?) AND date(?)
    GROUP BY e.category_id
    ORDER BY total_minutes DESC
  `
    )
    .all(startDate, endDate) as DayReportRow[]

  // Calculate number of days in range
  const start = new Date(startDate).getTime()
  const end = new Date(endDate).getTime()
  const numDays = Math.max(1, Math.round((end - start) / 86400000) + 1)

  return rows.map((r) => ({
    category_id: r.category_id,
    category_name: r.category_name,
    color: r.color,
    total_minutes: Math.round((r.total_minutes / numDays) * 10) / 10,
    entry_count: Math.round((r.entry_count / numDays) * 10) / 10
  }))
}
