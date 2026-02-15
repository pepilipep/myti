import type { WeekTimeline } from '@shared/types'
import { useState } from 'react'

interface Props {
  report: WeekTimeline
  onDayClick: (date: string) => void
}

interface Tooltip {
  text: string
  x: number
  y: number
}

const DAY_NAMES = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
const HOUR_HEIGHT = 36
const START_HOUR = 6
const END_HOUR = 24
const TOTAL_HOURS = END_HOUR - START_HOUR
const COLUMN_HEIGHT = TOTAL_HOURS * HOUR_HEIGHT

function CalendarView({ report, onDayClick }: Props): JSX.Element {
  const today = new Date().toISOString().split('T')[0]
  const [tooltip, setTooltip] = useState<Tooltip | null>(null)

  const hourLabels: number[] = []
  for (let h = START_HOUR; h < END_HOUR; h++) hourLabels.push(h)

  return (
    <div style={{ display: 'flex', gap: 0, position: 'relative' }}>
      {/* Tooltip */}
      {tooltip && (
        <div
          style={{
            position: 'fixed',
            left: tooltip.x - 8,
            top: tooltip.y - 28,
            transform: 'translateX(-100%)',
            background: '#1a1a2e',
            border: '1px solid #404050',
            borderRadius: 4,
            padding: '4px 8px',
            fontSize: 11,
            color: '#e0e0e8',
            whiteSpace: 'nowrap',
            pointerEvents: 'none',
            zIndex: 1000
          }}
        >
          {tooltip.text}
        </div>
      )}

      {/* Hour labels column */}
      <div style={{ width: 32, flexShrink: 0, paddingTop: 36 }}>
        <div style={{ position: 'relative', height: COLUMN_HEIGHT }}>
          {hourLabels.map((h) => (
            <div
              key={h}
              style={{
                position: 'absolute',
                top: (h - START_HOUR) * HOUR_HEIGHT,
                right: 4,
                fontSize: 10,
                color: '#555',
                lineHeight: '1'
              }}
            >
              {h}
            </div>
          ))}
        </div>
      </div>

      {/* Day columns */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 3, flex: 1 }}>
        {report.days.map((day, i) => {
          const isToday = day.date === today
          const dayDate = new Date(day.date + 'T00:00:00')
          const dateNum = dayDate.getDate()
          const hours = Math.round((day.total_minutes / 60) * 10) / 10

          return (
            <div
              key={day.date}
              onClick={() => onDayClick(day.date)}
              style={{
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                cursor: 'pointer',
                gap: 2
              }}
            >
              {/* Header */}
              <div style={{ fontSize: 11, color: isToday ? '#3B82F6' : '#888', fontWeight: 600 }}>
                {DAY_NAMES[i]}
              </div>
              <div
                style={{
                  fontSize: 12,
                  color: isToday ? '#3B82F6' : '#ccc',
                  fontWeight: isToday ? 600 : 400,
                  marginBottom: 2
                }}
              >
                {dateNum}
              </div>

              {/* Timeline column */}
              <div
                style={{
                  position: 'relative',
                  width: '100%',
                  height: COLUMN_HEIGHT,
                  background: isToday ? '#1e2444' : '#1a1a2e',
                  borderRadius: 6,
                  border: isToday ? '1px solid #3B82F6' : '1px solid #252540',
                  overflow: 'hidden'
                }}
              >
                {/* Hour gridlines */}
                {hourLabels.map((h) => (
                  <div
                    key={h}
                    style={{
                      position: 'absolute',
                      top: (h - START_HOUR) * HOUR_HEIGHT,
                      left: 0,
                      right: 0,
                      height: 1,
                      background: '#ffffff08'
                    }}
                  />
                ))}

                {/* Entries */}
                {day.entries.map((entry, j) => {
                  // Entry covers the period *before* prompted_at
                  const endTime = new Date(entry.prompted_at)
                  const startTime = new Date(endTime.getTime() - entry.credited_minutes * 60_000)
                  const startMins = startTime.getHours() * 60 + startTime.getMinutes()
                  const startMin = START_HOUR * 60
                  const top = ((startMins - startMin) / (TOTAL_HOURS * 60)) * COLUMN_HEIGHT
                  const height = Math.max(3, (entry.credited_minutes / (TOTAL_HOURS * 60)) * COLUMN_HEIGHT)

                  if (startMins < startMin) return null

                  const fmt = (d: Date): string =>
                    d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
                  const label = `${entry.category_name} — ${fmt(startTime)}\u2013${fmt(endTime)}`

                  return (
                    <div
                      key={j}
                      onMouseEnter={(e) => setTooltip({ text: label, x: e.clientX, y: e.clientY })}
                      onMouseMove={(e) => setTooltip({ text: label, x: e.clientX, y: e.clientY })}
                      onMouseLeave={() => setTooltip(null)}
                      style={{
                        position: 'absolute',
                        top,
                        left: 2,
                        right: 2,
                        height,
                        background: entry.color,
                        borderRadius: 2,
                        opacity: 0.85
                      }}
                    />
                  )
                })}
              </div>

              {/* Total */}
              <div style={{ fontSize: 11, color: '#888' }}>
                {day.total_minutes > 0 ? `${hours}h` : '\u00A0'}
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}

export default CalendarView
