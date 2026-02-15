import { app } from 'electron'
import fs from 'fs'
import path from 'path'

const MAX_SIZE = 1_000_000 // 1 MB
const KEEP_LINES = 500

let logPath: string

export function initLogger(): void {
  logPath = path.join(app.getPath('userData'), 'myti.log')

  // Rotate if too large
  try {
    const stat = fs.statSync(logPath)
    if (stat.size > MAX_SIZE) {
      const content = fs.readFileSync(logPath, 'utf-8')
      const lines = content.split('\n')
      fs.writeFileSync(logPath, lines.slice(-KEEP_LINES).join('\n') + '\n')
    }
  } catch {
    // File doesn't exist yet — fine
  }
}

function write(level: string, msg: string): void {
  const line = `[${new Date().toISOString()}] [${level}] ${msg}\n`
  try {
    fs.appendFileSync(logPath, line)
  } catch {
    // Can't log — nothing to do
  }
}

export const log = {
  info(msg: string): void {
    write('INFO', msg)
  },
  warn(msg: string): void {
    write('WARN', msg)
  },
  error(msg: string, err?: unknown): void {
    const suffix = err instanceof Error ? ` — ${err.stack || err.message}` : ''
    write('ERROR', msg + suffix)
  }
}
