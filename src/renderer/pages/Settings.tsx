import { useState, useEffect, useCallback } from 'react'
import type { Category, Settings as SettingsType } from '@shared/types'

function Settings(): JSX.Element {
  const [settings, setSettings] = useState<SettingsType | null>(null)
  const [categories, setCategories] = useState<Category[]>([])
  const [editingCat, setEditingCat] = useState<Partial<Category> | null>(null)

  const loadData = useCallback(async () => {
    setSettings(await window.api.settingsGetAll())
    setCategories(await window.api.categoriesList())
  }, [])

  useEffect(() => {
    loadData() // eslint-disable-line react-hooks/set-state-in-effect
  }, [loadData])

  async function saveInterval(value: string): Promise<void> {
    const num = parseInt(value, 10)
    if (isNaN(num) || num < 1) return
    await window.api.settingsSet('interval_minutes', String(num))
    setSettings((s) => (s ? { ...s, interval_minutes: num } : s))
  }

  async function saveAfkThreshold(value: string): Promise<void> {
    const num = parseInt(value, 10)
    if (isNaN(num) || num < 1) return
    await window.api.settingsSet('afk_threshold_minutes', String(num))
    setSettings((s) => (s ? { ...s, afk_threshold_minutes: num } : s))
  }

  async function saveCat(): Promise<void> {
    if (!editingCat?.name || !editingCat?.color) return
    await window.api.categoriesUpsert(editingCat as Partial<Category> & { name: string; color: string })
    setEditingCat(null)
    setCategories(await window.api.categoriesList())
  }

  async function deleteCat(id: number): Promise<void> {
    await window.api.categoriesDelete(id)
    setCategories(await window.api.categoriesList())
  }

  if (!settings) return <div style={{ padding: 20, color: '#888' }}>Loading...</div>

  const input = {
    background: '#2a2a3e',
    border: '1px solid #3a3a4e',
    borderRadius: 4,
    color: '#e0e0e0',
    padding: '4px 8px',
    fontSize: 13,
    width: 80
  }
  const btn = {
    background: '#3B82F6',
    border: 'none',
    borderRadius: 4,
    color: '#fff',
    padding: '4px 12px',
    cursor: 'pointer',
    fontSize: 13
  }
  const btnDanger = { ...btn, background: '#EF4444' }
  const btnSecondary = { ...btn, background: '#2a2a3e', border: '1px solid #3a3a4e', color: '#e0e0e0' }

  return (
    <div style={{ padding: 20, height: '100vh', overflow: 'auto' }}>
      <h2 style={{ fontSize: 16, fontWeight: 600, marginBottom: 16 }}>Settings</h2>

      <div style={{ marginBottom: 20 }}>
        <label style={{ fontSize: 13, color: '#888', display: 'block', marginBottom: 4 }}>
          Prompt interval (minutes)
        </label>
        <input
          type="number"
          style={input}
          defaultValue={settings.interval_minutes}
          min={1}
          onBlur={(e) => saveInterval(e.target.value)}
        />
      </div>

      <div style={{ marginBottom: 20 }}>
        <label style={{ fontSize: 13, color: '#888', display: 'block', marginBottom: 4 }}>
          AFK threshold (minutes)
        </label>
        <input
          type="number"
          style={input}
          defaultValue={settings.afk_threshold_minutes}
          min={1}
          onBlur={(e) => saveAfkThreshold(e.target.value)}
        />
      </div>

      <h3 style={{ fontSize: 14, fontWeight: 600, marginBottom: 8 }}>Categories</h3>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 6, marginBottom: 12 }}>
        {categories.map((cat) => (
          <div key={cat.id} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <div style={{ width: 16, height: 16, borderRadius: 3, background: cat.color, flexShrink: 0 }} />
            <span style={{ flex: 1, fontSize: 13 }}>{cat.name}</span>
            <button
              style={btnSecondary}
              onClick={() => setEditingCat({ id: cat.id, name: cat.name, color: cat.color })}
            >
              Edit
            </button>
            <button style={btnDanger} onClick={() => deleteCat(cat.id)}>
              Delete
            </button>
          </div>
        ))}
      </div>

      {editingCat ? (
        <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
          <input
            style={{ ...input, width: 140 }}
            placeholder="Name"
            value={editingCat.name ?? ''}
            onChange={(e) => setEditingCat({ ...editingCat, name: e.target.value })}
          />
          <input
            type="color"
            value={editingCat.color ?? '#3B82F6'}
            onChange={(e) => setEditingCat({ ...editingCat, color: e.target.value })}
            style={{ width: 32, height: 28, border: 'none', background: 'none', cursor: 'pointer' }}
          />
          <button style={btn} onClick={saveCat}>
            Save
          </button>
          <button style={btnSecondary} onClick={() => setEditingCat(null)}>
            Cancel
          </button>
        </div>
      ) : (
        <button style={btn} onClick={() => setEditingCat({ name: '', color: '#3B82F6' })}>
          + Add Category
        </button>
      )}
    </div>
  )
}

export default Settings
