import { getDb } from './database'
import type { Category } from '@shared/types'

interface CategoryRow {
  id: number
  name: string
  color: string
  sort_order: number
  is_active: number
}

export function listCategories(activeOnly = true): Category[] {
  const db = getDb()
  const where = activeOnly ? 'WHERE is_active = 1' : ''
  const rows = db.prepare(`SELECT * FROM categories ${where} ORDER BY sort_order ASC`).all() as CategoryRow[]
  return rows.map(toCategory)
}

export function upsertCategory(data: Partial<Category> & { name: string; color: string }): Category {
  const db = getDb()
  if (data.id) {
    db.prepare('UPDATE categories SET name = ?, color = ?, sort_order = ?, is_active = ? WHERE id = ?').run(
      data.name,
      data.color,
      data.sort_order ?? 0,
      data.is_active !== false ? 1 : 0,
      data.id
    )
    return toCategory(db.prepare('SELECT * FROM categories WHERE id = ?').get(data.id) as CategoryRow)
  } else {
    const maxOrder = db.prepare('SELECT MAX(sort_order) as m FROM categories').get() as { m: number | null }
    const result = db
      .prepare('INSERT INTO categories (name, color, sort_order) VALUES (?, ?, ?)')
      .run(data.name, data.color, data.sort_order ?? (maxOrder.m ?? -1) + 1)
    return toCategory(
      db.prepare('SELECT * FROM categories WHERE id = ?').get(result.lastInsertRowid) as CategoryRow
    )
  }
}

export function deleteCategory(id: number): void {
  const db = getDb()
  // Soft delete — just deactivate so existing entries still reference it
  db.prepare('UPDATE categories SET is_active = 0 WHERE id = ?').run(id)
}

function toCategory(row: CategoryRow): Category {
  return {
    id: row.id,
    name: row.name,
    color: row.color,
    sort_order: row.sort_order,
    is_active: row.is_active === 1
  }
}
