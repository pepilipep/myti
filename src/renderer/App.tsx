import { Routes, Route } from 'react-router-dom'
import Popup from './pages/Popup'
import Reports from './pages/Reports'
import Settings from './pages/Settings'
import MeetingConfirm from './pages/MeetingConfirm'

function App(): JSX.Element {
  return (
    <Routes>
      <Route path="/popup" element={<Popup />} />
      <Route path="/reports" element={<Reports />} />
      <Route path="/settings" element={<Settings />} />
      <Route path="/meeting-confirm" element={<MeetingConfirm />} />
    </Routes>
  )
}

export default App
