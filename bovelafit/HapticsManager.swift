import SwiftUI
import Combine

final class HapticsManager: ObservableObject {
    enum Intensity { case low, medium, high }
    @Published var enabled = true
    @Published var intensity: Intensity = .medium

    func tap() {
        guard enabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style(for: intensity))
        generator.impactOccurred()
    }

    func success() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func warning() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    func blockChange() {
        guard enabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred(intensity: 1.0)
    }

    private func style(for level: Intensity) -> UIImpactFeedbackGenerator.FeedbackStyle {
        switch level {
        case .low: return .light
        case .medium: return .medium
        case .high: return .heavy
        }
    }
}
