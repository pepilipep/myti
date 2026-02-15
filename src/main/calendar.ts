import { execFile } from 'child_process'
import type { BusyBlock } from '@shared/types'
import { log } from './logger'

const APPLESCRIPT = `
tell application "Calendar"
  set now to current date
  set later to now + (1 * hours)
  set output to ""
  repeat with cal in calendars
    set evts to (every event of cal whose start date ≥ now and start date ≤ later)
    repeat with e in evts
      set output to output & summary of e & "||" & ((start date of e) as string) & "||" & ((end date of e) as string) & linefeed
    end repeat
  end repeat
  return output
end tell
`

interface CalendarEvent {
  title: string
  start: Date
  end: Date
}

function parseAppleScriptDate(dateStr: string): Date {
  // macOS AppleScript dates come in locale-dependent format like "Friday, January 10, 2025 at 10:00:00 AM"
  // Date.parse handles most of these, but we strip "at " to help
  const cleaned = dateStr.replace(/\s+at\s+/, ' ').trim()
  const d = new Date(cleaned)
  if (isNaN(d.getTime())) {
    throw new Error(`Failed to parse date: ${dateStr}`)
  }
  return d
}

function parseOutput(output: string): CalendarEvent[] {
  const events: CalendarEvent[] = []
  const lines = output.trim().split('\n')
  for (const line of lines) {
    if (!line.trim()) continue
    const parts = line.split('||')
    if (parts.length < 3) continue
    try {
      events.push({
        title: parts[0].trim(),
        start: parseAppleScriptDate(parts[1]),
        end: parseAppleScriptDate(parts[2])
      })
    } catch {
      // skip unparseable events
    }
  }
  return events
}

function mergeOverlapping(events: CalendarEvent[]): CalendarEvent[] {
  if (events.length === 0) return []
  events.sort((a, b) => a.start.getTime() - b.start.getTime())

  const merged: CalendarEvent[] = [{ ...events[0] }]
  for (let i = 1; i < events.length; i++) {
    const last = merged[merged.length - 1]
    const curr = events[i]
    // Merge if overlapping or adjacent (within 5 min gap)
    if (curr.start.getTime() <= last.end.getTime() + 5 * 60 * 1000) {
      if (curr.end.getTime() > last.end.getTime()) {
        last.end = curr.end
      }
      if (last.title !== curr.title) {
        last.title = `${last.title} + ${curr.title}`
      }
    } else {
      merged.push({ ...curr })
    }
  }
  return merged
}

export function getUpcomingBusyBlock(): Promise<BusyBlock | null> {
  return new Promise((resolve) => {
    execFile('osascript', ['-e', APPLESCRIPT], { timeout: 10000 }, (error, stdout) => {
      if (error) {
        log.error('Calendar query failed', error)
        resolve(null)
        return
      }

      if (!stdout.trim()) {
        resolve(null)
        return
      }

      const events = parseOutput(stdout)
      if (events.length === 0) {
        resolve(null)
        return
      }

      const blocks = mergeOverlapping(events)
      const now = new Date()
      const firstBlock = blocks.find((b) => b.end.getTime() > now.getTime())
      if (!firstBlock) {
        resolve(null)
        return
      }

      resolve({
        start: firstBlock.start.toISOString(),
        end: firstBlock.end.toISOString(),
        title: firstBlock.title
      })
    })
  })
}
