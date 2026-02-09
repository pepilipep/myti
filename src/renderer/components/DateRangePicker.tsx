interface Props {
  label: string
  onPrev: () => void
  onNext: () => void
  onToday: () => void
}

function DateRangePicker({ label, onPrev, onNext, onToday }: Props): JSX.Element {
  const btn = {
    background: '#2a2a3e',
    border: '1px solid #3a3a4e',
    borderRadius: 4,
    color: '#e0e0e0',
    padding: '4px 10px',
    cursor: 'pointer',
    fontSize: 13
  }

  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
      <button style={btn} onClick={onPrev}>
        &larr;
      </button>
      <span style={{ fontSize: 14, fontWeight: 500, minWidth: 140, textAlign: 'center' }}>{label}</span>
      <button style={btn} onClick={onNext}>
        &rarr;
      </button>
      <button style={{ ...btn, marginLeft: 8 }} onClick={onToday}>
        Today
      </button>
    </div>
  )
}

export default DateRangePicker
