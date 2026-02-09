import type { WeekTimeline } from '@shared/types'

interface Props {
  report: WeekTimeline
  onDayClick: (date: string) => void
}

const DAY_NAMES = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
const HOUR_HEIGHT = 28
const START_HOUR = 6
const END_HOUR = 24
const TOTAL_HOURS = END_HOUR - START_HOUR
const COLUMN_HEIGHT = TOTAL_HOURS * HOUR_HEIGHT

function getMinutesFromMidnight(isoString: string): number {
  const d = new Date(isoString)
  return d.getHours() * 60 + d.getMinutes()
}

function CalendarView({ report, onDayClick }: Props): JSX.Element {
  const today = new Date().toISOString().split('T')[0]

  const hourLabels: number[] = []
  for (let h = START_HOUR; h < END_HOUR; h++) hourLabels.push(h)

  return (
    <div style={{ display: 'flex', gap: 0 }}>
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
                  const mins = getMinutesFromMidnight(entry.prompted_at)
                  const startMin = START_HOUR * 60
                  const top = ((mins - startMin) / (TOTAL_HOURS * 60)) * COLUMN_HEIGHT
                  const height = Math.max(3, (entry.credited_minutes / (TOTAL_HOURS * 60)) * COLUMN_HEIGHT)

                  if (mins < startMin) return null

                  return (
                    <div
                      key={j}
                      title={`${entry.category_name} — ${new Date(entry.prompted_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })} (${entry.credited_minutes}m)`}
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
