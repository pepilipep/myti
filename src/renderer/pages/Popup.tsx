import { useState, useEffect, useCallback } from 'react'
import type { Category, PopupData } from '@shared/types'
import CategoryButton from '../components/CategoryButton'
import { useKeyboard } from '../hooks/useKeyboard'

function Popup(): JSX.Element {
  const [categories, setCategories] = useState<Category[]>([])
  const [promptedAt, setPromptedAt] = useState<string>('')

  useEffect(() => {
    const unsub = window.api.onPopupShow((data: PopupData) => {
      setCategories(data.categories)
      setPromptedAt(data.promptedAt)
    })
    return unsub
  }, [])

  const submit = useCallback(
    (index: number) => {
      if (!promptedAt || !categories[index]) return
      window.api.entrySubmit(categories[index].id, promptedAt)
    },
    [categories, promptedAt]
  )

  useKeyboard(submit, categories.length)

  return (
    <div
      style={{
        padding: 12,
        height: '100vh',
        display: 'flex',
        flexDirection: 'column',
        WebkitAppRegion: 'drag' as unknown as string
      }}
    >
      <div
        style={{
          fontSize: 13,
          fontWeight: 600,
          marginBottom: 8,
          color: '#a0a0b0',
          textAlign: 'center'
        }}
      >
        What were you doing?
      </div>
      <div
        style={{
          flex: 1,
          display: 'flex',
          flexDirection: 'column',
          gap: 4,
          overflowY: 'auto',
          WebkitAppRegion: 'no-drag' as unknown as string
        }}
      >
        {categories.map((cat, i) => (
          <CategoryButton key={cat.id} category={cat} index={i} onClick={() => submit(i)} />
        ))}
      </div>
    </div>
  )
}

export default Popup
