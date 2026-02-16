import { BarChart, Bar, XAxis, YAxis, Tooltip, Legend, ResponsiveContainer } from 'recharts'
import type { WeekReport } from '@shared/types'
import { formatMinutes } from '../utils/format'

interface Props {
  report: WeekReport
}

const DAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']

function WeekSummary({ report }: Props): JSX.Element {
  if (report.total_minutes === 0) {
    return <div style={{ color: '#666', textAlign: 'center', padding: 20 }}>No entries for this week</div>
  }

  // Build stacked data: each day has a bar with category breakdowns
  const allCategories = report.totals.map((t) => ({
    id: t.category_id,
    name: t.category_name,
    color: t.color
  }))

  const data = report.days.map((day, i) => {
    const row: Record<string, string | number> = { name: DAYS[i] }
    for (const cat of allCategories) {
      const entry = day.entries.find((e) => e.category_id === cat.id)
      row[cat.name] = entry ? entry.total_minutes : 0
    }
    return row
  })

  return (
    <div>
      <div style={{ fontSize: 13, color: '#888', marginBottom: 8 }}>
        Week total: {formatMinutes(report.total_minutes)}
      </div>
      <ResponsiveContainer width="100%" height={300}>
        <BarChart data={data} margin={{ left: 10, right: 10, top: 5, bottom: 5 }}>
          <XAxis dataKey="name" stroke="#666" />
          <YAxis tickFormatter={(v) => `${v}m`} stroke="#666" />
          <Tooltip
            contentStyle={{ background: '#2a2a3e', border: 'none', borderRadius: 6, color: '#e0e0e0' }}
            formatter={(value: number) => formatMinutes(value)}
          />
          <Legend wrapperStyle={{ fontSize: 11 }} />
          {allCategories.map((cat) => (
            <Bar key={cat.id} dataKey={cat.name} stackId="a" fill={cat.color} />
          ))}
        </BarChart>
      </ResponsiveContainer>
    </div>
  )
}

export default WeekSummary
