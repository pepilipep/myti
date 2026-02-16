import { BarChart, Bar, XAxis, YAxis, Tooltip, Cell, ResponsiveContainer } from 'recharts'
import type { DayReport } from '@shared/types'
import { formatMinutes } from '../utils/format'

interface Props {
  report: DayReport
}

function DaySummary({ report }: Props): JSX.Element {
  if (report.entries.length === 0) {
    return <div style={{ color: '#666', textAlign: 'center', padding: 20 }}>No entries for this day</div>
  }

  const data = report.entries.map((e) => ({
    name: e.category_name,
    minutes: e.total_minutes,
    color: e.color
  }))

  return (
    <div>
      <div style={{ fontSize: 13, color: '#888', marginBottom: 8 }}>
        Total: {formatMinutes(report.total_minutes)}
      </div>
      <ResponsiveContainer width="100%" height={Math.max(200, data.length * 40)}>
        <BarChart data={data} layout="vertical" margin={{ left: 80, right: 20, top: 5, bottom: 5 }}>
          <XAxis type="number" tickFormatter={(v) => `${v}m`} stroke="#666" />
          <YAxis type="category" dataKey="name" stroke="#666" width={75} tick={{ fontSize: 12 }} />
          <Tooltip
            formatter={(value: number) => formatMinutes(value)}
            contentStyle={{ background: '#2a2a3e', border: 'none', borderRadius: 6, color: '#e0e0e0' }}
          />
          <Bar dataKey="minutes" radius={[0, 4, 4, 0]}>
            {data.map((entry, i) => (
              <Cell key={i} fill={entry.color} />
            ))}
          </Bar>
        </BarChart>
      </ResponsiveContainer>
    </div>
  )
}

export default DaySummary
