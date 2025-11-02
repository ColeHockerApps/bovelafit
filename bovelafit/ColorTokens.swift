import SwiftUI
import Combine

enum ColorTokens {
    static let bg = Color(red: 0.07, green: 0.08, blue: 0.10)
    static let surface = Color(red: 0.12, green: 0.13, blue: 0.16)
    static let surface2 = Color(red: 0.16, green: 0.17, blue: 0.20)
    static let cardBackground = surface
    static let cardStroke = Color.white.opacity(0.06)

    static let accent = Color(red: 0.40, green: 0.70, blue: 1.00)
    static let accent2 = Color(red: 0.55, green: 0.45, blue: 1.00)

    static let success = Color(red: 0.30, green: 0.85, blue: 0.55)
    static let warning = Color(red: 1.00, green: 0.74, blue: 0.25)
    static let error = Color(red: 1.00, green: 0.36, blue: 0.36)
    static let info = Color(red: 0.40, green: 0.70, blue: 1.00)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)

    static var accentGradient: LinearGradient {
        LinearGradient(colors: [accent2, accent], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func blockColor(_ type: BlockType) -> Color {
        switch type {
        case .warmup: return Color(red: 1.00, green: 0.72, blue: 0.30)
        case .work: return Color(red: 0.95, green: 0.35, blue: 0.45)
        case .recover: return Color(red: 0.30, green: 0.85, blue: 0.55)
        case .cooldown: return Color(red: 0.40, green: 0.70, blue: 1.00)
        case .rampUp: return Color(red: 0.70, green: 0.55, blue: 1.00)
        case .rampDown: return Color(red: 0.55, green: 0.80, blue: 1.00)
        case .repeatGroup: return Color(red: 0.85, green: 0.65, blue: 0.95)
        }
    }
}
