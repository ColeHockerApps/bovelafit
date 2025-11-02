import Foundation
import Combine

enum BeatPattern {
    case direct
    case every(Int) // group every N beats for high tempos
}

enum TempoEngine {
    static func interval(for spm: Int) -> TimeInterval {
        guard spm > 0 else { return 1.0 }
        return 60.0 / Double(spm)
    }

    static func pattern(for spm: Int) -> BeatPattern {
        if spm >= 200 { return .every(4) }
        if spm >= 170 { return .every(2) }
        return .direct
    }

    static func effectiveTempo(from target: TempoTarget) -> Int {
        switch target.mode {
        case .none: return 0
        case .fixed: return clamp(target.value ?? 0)
        case .range:
            let lo = clamp(target.min ?? 0)
            let hi = clamp(target.max ?? 0)
            return (lo + hi) > 0 ? Int(round(Double(lo + hi) / 2.0)) : 0
        }
    }

    static func rampValue(start: Int, end: Int, progress01: Double) -> Int {
        let p = min(max(progress01, 0.0), 1.0)
        let v = Double(start) + (Double(end - start) * p)
        return clamp(Int(round(v)))
    }

    static func clamp(_ spm: Int) -> Int {
        return min(max(spm, 40), 300)
    }
}
