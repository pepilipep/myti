import React, { Component, type ReactNode } from 'react'

interface ErrorInfo {
  message: string
  stack?: string
}

interface State {
  errors: ErrorInfo[]
}

export class ErrorBoundary extends Component<{ children: ReactNode }, State> {
  state: State = { errors: [] }

  componentDidCatch(error: Error): void {
    this.addError({ message: error.message, stack: error.stack })
  }

  componentDidMount(): void {
    window.onerror = (_msg, _src, _line, _col, error) => {
      this.addError({
        message: error?.message || String(_msg),
        stack: error?.stack
      })
    }
    window.onunhandledrejection = (event: PromiseRejectionEvent) => {
      const err = event.reason
      this.addError({
        message: err instanceof Error ? err.message : String(err),
        stack: err instanceof Error ? err.stack : undefined
      })
    }
  }

  addError(info: ErrorInfo): void {
    this.setState((prev) => ({ errors: [...prev.errors, info] }))
  }

  dismiss = (index: number): void => {
    this.setState((prev) => ({ errors: prev.errors.filter((_, i) => i !== index) }))
  }

  render(): ReactNode {
    return (
      <>
        {this.props.children}
        {this.state.errors.length > 0 && (
          <div style={overlayStyle}>
            {this.state.errors.map((err, i) => (
              <div key={i} style={errorStyle}>
                <div style={headerStyle}>
                  <span style={{ fontWeight: 'bold' }}>Error: {err.message}</span>
                  <button onClick={() => this.dismiss(i)} style={closeStyle}>
                    ✕
                  </button>
                </div>
                {err.stack && <pre style={stackStyle}>{err.stack}</pre>}
              </div>
            ))}
          </div>
        )}
      </>
    )
  }
}

const overlayStyle: React.CSSProperties = {
  position: 'fixed',
  bottom: 0,
  left: 0,
  right: 0,
  maxHeight: '40vh',
  overflowY: 'auto',
  zIndex: 99999,
  padding: 8
}

const errorStyle: React.CSSProperties = {
  background: '#1a0000',
  border: '1px solid #ff4444',
  borderRadius: 4,
  padding: 8,
  marginBottom: 4,
  fontFamily: 'monospace',
  fontSize: 12,
  color: '#ff8888'
}

const headerStyle: React.CSSProperties = {
  display: 'flex',
  justifyContent: 'space-between',
  alignItems: 'center'
}

const closeStyle: React.CSSProperties = {
  background: 'none',
  border: 'none',
  color: '#ff8888',
  cursor: 'pointer',
  fontSize: 14,
  padding: '0 4px'
}

const stackStyle: React.CSSProperties = {
  margin: '4px 0 0',
  whiteSpace: 'pre-wrap',
  wordBreak: 'break-all',
  fontSize: 11,
  color: '#cc6666',
  maxHeight: 120,
  overflowY: 'auto'
}
