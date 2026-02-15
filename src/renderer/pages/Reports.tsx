import { useState, useEffect, useCallback } from 'react'
import type { DayReport, WeekReport, WeekTimeline, DayReportEntry } from '@shared/types'
import DaySummary from '../components/DaySummary'
import WeekSummary from '../components/WeekSummary'
import CalendarView from '../components/CalendarView'
import DateRangePicker from '../components/DateRangePicker'

type View = 'day' | 'week' | 'average'

function todayStr(): string {
  return new Date().toISOString().split('T')[0]
}

function addDays(date: string, n: number): string {
  const d = new Date(date)
  d.setDate(d.getDate() + n)
  return d.toISOString().split('T')[0]
}

function Reports(): JSX.Element {
  const [view, setView] = useState<View>('day')
  const [date, setDate] = useState(todayStr())
  const [dayReport, setDayReport] = useState<DayReport | null>(null)
  const [weekReport, setWeekReport] = useState<WeekReport | null>(null)
  const [weekTimeline, setWeekTimeline] = useState<WeekTimeline | null>(null)
  const [avgReport, setAvgReport] = useState<DayReportEntry[]>([])

  const load = useCallback(async () => {
    if (view === 'day') {
      setDayReport(await window.api.reportDay(date))
    } else if (view === 'week') {
      const [report, timeline] = await Promise.all([
        window.api.reportWeek(date),
        window.api.reportWeekTimeline(date)
      ])
      setWeekReport(report)
      setWeekTimeline(timeline)
    } else {
      // Average over last 30 days
      const end = todayStr()
      const start = addDays(end, -29)
      setAvgReport(await window.api.reportAverage(start, end))
    }
  }, [view, date])

  useEffect(() => {
    load() // eslint-disable-line react-hooks/set-state-in-effect
  }, [load])

  const tabStyle = (v: View) => ({
    padding: '6px 16px',
    border: 'none',
    borderRadius: 6,
    background: view === v ? '#3B82F6' : '#2a2a3e',
    color: '#e0e0e0',
    cursor: 'pointer' as const,
    fontSize: 13,
    fontWeight: view === v ? 600 : 400
  })

  return (
    <div style={{ padding: 20, height: '100vh', overflow: 'auto' }}>
      <div style={{ display: 'flex', gap: 8, marginBottom: 16 }}>
        <button style={tabStyle('day')} onClick={() => setView('day')}>
          Day
        </button>
        <button style={tabStyle('week')} onClick={() => setView('week')}>
          Week
        </button>
        <button style={tabStyle('average')} onClick={() => setView('average')}>
          Average
        </button>
      </div>

      {view !== 'average' && (
        <div style={{ marginBottom: 16 }}>
          <DateRangePicker
            label={
              view === 'day' ? date : weekReport ? `${weekReport.start_date} — ${weekReport.end_date}` : date
            }
            onPrev={() => setDate(addDays(date, view === 'day' ? -1 : -7))}
            onNext={() => setDate(addDays(date, view === 'day' ? 1 : 7))}
            onToday={() => setDate(todayStr())}
          />
        </div>
      )}

      {view === 'day' && dayReport && <DaySummary report={dayReport} />}
      {view === 'week' && weekTimeline && (
        <div style={{ marginBottom: 16 }}>
          <CalendarView
            report={weekTimeline}
            onDayClick={(d) => {
              setDate(d)
              setView('day')
            }}
          />
        </div>
      )}
      {view === 'week' && weekReport && <WeekSummary report={weekReport} />}
      {view === 'average' && (
        <div>
          <div style={{ fontSize: 13, color: '#888', marginBottom: 12 }}>Daily average (last 30 days)</div>
          {avgReport.length === 0 ? (
            <div style={{ color: '#666', textAlign: 'center', padding: 20 }}>No data yet</div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
              {avgReport.map((entry) => (
                <div
                  key={entry.category_id}
                  style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 13 }}
                >
                  <div
                    style={{
                      width: 12,
                      height: 12,
                      borderRadius: 3,
                      background: entry.color,
                      flexShrink: 0
                    }}
                  />
                  <span style={{ flex: 1 }}>{entry.category_name}</span>
                  <span style={{ color: '#888' }}>{entry.total_minutes}m/day</span>
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  )
}

export default Reports
