import Foundation
import Combine

enum Formatters {
    static func time(_ sec: Int) -> String {
        let m = sec / 60
        let s = sec % 60
        return String(format: "%02d:%02d", m, s)
    }

    static func tempo(_ target: TempoTarget) -> String {
        switch target.mode {
        case .none:
            return "—"
        case .fixed:
            return "\(target.value ?? 0) spm"
        case .range:
            let minV = target.min ?? 0
            let maxV = target.max ?? 0
            return "\(minV)–\(maxV) spm"
        }
    }

    static func date(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df.string(from: date)
    }

    static func percent(_ value: Double?) -> String {
        guard let v = value else { return "—" }
        return String(format: "%.0f%%", v * 100)
    }
}
