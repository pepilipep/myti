import SwiftUI

enum AppColors {
    static let background = Color(hex: "#1a1a2e")
    static let surface = Color(hex: "#2a2a3e")
    static let border = Color(hex: "#3a3a4e")
    static let borderSubtle = Color(hex: "#252540")
    static let text = Color(hex: "#e0e0e0")
    static let textBright = Color(hex: "#e0e0e8")
    static let textMuted = Color(hex: "#a0a0b0")
    static let textDim = Color(hex: "#808090")
    static let textDimmer = Color(hex: "#888888")
    static let textDimmest = Color(hex: "#666666")
    static let accent = Color(hex: "#3B82F6")
    static let danger = Color(hex: "#EF4444")
    static let todayBackground = Color(hex: "#1e2444")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b, a: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
            a = 1
        case 8:
            r = Double((int >> 24) & 0xFF) / 255
            g = Double((int >> 16) & 0xFF) / 255
            b = Double((int >> 8) & 0xFF) / 255
            a = Double(int & 0xFF) / 255
        default:
            r = 0; g = 0; b = 0; a = 1
        }
        self.init(red: r, green: g, blue: b, opacity: a)
    }

    /// Create a color from a hex string with a given opacity
    static func hex(_ hex: String, opacity: Double = 1.0) -> Color {
        Color(hex: hex).opacity(opacity)
    }
}
