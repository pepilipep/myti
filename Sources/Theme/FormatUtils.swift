import Foundation

func formatAverageTime(_ m: Double) -> String {
    if m >= 60 {
        let hrs = m / 60
        return String(format: "%.1fh", hrs)
    }
    return String(format: "%.1fm", m)
}

func formatMinutes(_ m: Double) -> String {
    let hrs = Int(m / 60)
    let mins = Int(m.truncatingRemainder(dividingBy: 60).rounded())
    if hrs > 0 {
        return "\(hrs)h \(mins)m"
    }
    return "\(mins)m"
}
