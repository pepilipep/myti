import Foundation

func formatMinutes(_ m: Double) -> String {
    let hrs = Int(m / 60)
    let mins = Int(m.truncatingRemainder(dividingBy: 60).rounded())
    if hrs > 0 {
        return "\(hrs)h \(mins)m"
    }
    return "\(mins)m"
}
