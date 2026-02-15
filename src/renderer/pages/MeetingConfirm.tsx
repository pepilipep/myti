import { useState, useEffect, useCallback } from 'react'
import type { MeetingPopupData, BusyBlock } from '@shared/types'

function MeetingConfirm(): JSX.Element {
  const [data, setData] = useState<MeetingPopupData | null>(null)

  useEffect(() => {
    const unsub = window.api.onMeetingPopupShow((d: MeetingPopupData) => {
      setData(d)
    })
    return unsub
  }, [])

  const confirm = useCallback((block: BusyBlock) => {
    window.api.meetingConfirm(block)
  }, [])

  const decline = useCallback(() => {
    window.api.meetingDecline()
  }, [])

  useEffect(() => {
    if (!data) return
    const handler = (e: KeyboardEvent): void => {
      if (e.key === 'y' || e.key === 'Y') {
        confirm(data.busyBlock)
      } else if (e.key === 'n' || e.key === 'N' || e.key === 'Escape') {
        decline()
      }
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [data, confirm, decline])

  if (!data) return <div />

  return (
    <div
      style={{
        padding: 16,
        height: '100vh',
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'center',
        alignItems: 'center',
        gap: 12,
        WebkitAppRegion: 'drag' as unknown as string
      }}
    >
      <div style={{ fontSize: 13, color: '#a0a0b0', textAlign: 'center' }}>Upcoming meeting</div>
      <div style={{ fontSize: 15, fontWeight: 600, color: '#e0e0e8', textAlign: 'center' }}>
        {data.busyBlock.title}
      </div>
      <div style={{ fontSize: 13, color: '#808090' }}>{data.formattedTime}</div>
      <div style={{ fontSize: 13, color: '#a0a0b0', marginTop: 4 }}>Are you going to attend?</div>
      <div
        style={{
          display: 'flex',
          gap: 8,
          WebkitAppRegion: 'no-drag' as unknown as string
        }}
      >
        <button
          onClick={() => confirm(data.busyBlock)}
          style={{
            padding: '6px 20px',
            borderRadius: 6,
            border: 'none',
            background: '#4a9eff',
            color: '#fff',
            fontSize: 13,
            fontWeight: 600,
            cursor: 'pointer'
          }}
        >
          Yes (Y)
        </button>
        <button
          onClick={decline}
          style={{
            padding: '6px 20px',
            borderRadius: 6,
            border: '1px solid #404050',
            background: 'transparent',
            color: '#a0a0b0',
            fontSize: 13,
            cursor: 'pointer'
          }}
        >
          No (N)
        </button>
      </div>
    </div>
  )
}

export default MeetingConfirm
