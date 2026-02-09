import { useEffect } from 'react'

export function useKeyboard(onKey: (index: number) => void, maxIndex: number): void {
  useEffect(() => {
    const handler = (e: KeyboardEvent): void => {
      const num = parseInt(e.key, 10)
      if (num >= 1 && num <= Math.min(9, maxIndex)) {
        onKey(num - 1)
      }
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [onKey, maxIndex])
}
