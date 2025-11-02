import Foundation
import Combine

final class HomeViewModel: ObservableObject {
    @Published var quickDuration: Int = 600
    @Published var quickTempoMode: TempoMode = .fixed
    @Published var quickTempoFixed: Int = 170
    @Published var quickTempoMin: Int = 160
    @Published var quickTempoMax: Int = 180

    func quickBlocks() -> [Block] {
        let target: TempoTarget = {
            switch quickTempoMode {
            case .none:
                return TempoTarget(mode: .none, value: nil, min: nil, max: nil)
            case .fixed:
                return TempoTarget(mode: .fixed, value: quickTempoFixed, min: nil, max: nil)
            case .range:
                return TempoTarget(mode: .range, value: nil, min: quickTempoMin, max: quickTempoMax)
            }
        }()
        return [
            Block(
                type: .work,
                durationSec: quickDuration,
                tempo: target,
                repeatCount: nil,
                subblocks: nil,
                rampStart: nil,
                rampEnd: nil
            )
        ]
    }

    func validate() -> Bool {
        switch quickTempoMode {
        case .none:
            return quickDuration > 0
        case .fixed:
            return quickDuration > 0 && quickTempoFixed >= 40 && quickTempoFixed <= 300
        case .range:
            return quickDuration > 0 && quickTempoMin >= 40 && quickTempoMax <= 300 && quickTempoMin <= quickTempoMax
        }
    }
}
