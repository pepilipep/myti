import type { Category } from '@shared/types'

interface Props {
  category: Category
  index: number
  onClick: () => void
}

function CategoryButton({ category, index, onClick }: Props): JSX.Element {
  return (
    <button
      onClick={onClick}
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: 8,
        width: '100%',
        padding: '6px 10px',
        border: 'none',
        borderRadius: 6,
        background: `${category.color}22`,
        color: '#e0e0e0',
        cursor: 'pointer',
        fontSize: 13,
        textAlign: 'left',
        transition: 'background 0.15s'
      }}
      onMouseEnter={(e) => (e.currentTarget.style.background = `${category.color}44`)}
      onMouseLeave={(e) => (e.currentTarget.style.background = `${category.color}22`)}
    >
      <span
        style={{
          width: 20,
          height: 20,
          borderRadius: 4,
          background: category.color,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          fontSize: 11,
          fontWeight: 600,
          color: '#fff',
          flexShrink: 0
        }}
      >
        {index + 1}
      </span>
      <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
        {category.name}
      </span>
    </button>
  )
}

export default CategoryButton
