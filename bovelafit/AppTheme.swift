import SwiftUI
import Combine

enum AppTheme {
    static let cornerRadius: CGFloat = 16
    static let spacing: CGFloat = 12
    static let cardPadding: CGFloat = 14
    static let pillPadding: EdgeInsets = .init(top: 4, leading: 10, bottom: 4, trailing: 10)
}

extension View {
    func cardStyle() -> some View {
        self
            .padding(AppTheme.cardPadding)
            .background(ColorTokens.cardBackground, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(ColorTokens.cardStroke, lineWidth: 0.5)
            )
    }

    func pillStyle(_ color: Color) -> some View {
        self
            .padding(AppTheme.pillPadding)
            .background(
                Capsule(style: .continuous)
                    .fill(color.opacity(0.20))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(color.opacity(0.45), lineWidth: 0.8)
            )
    }
}
