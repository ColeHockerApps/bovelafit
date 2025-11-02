import Foundation
import Combine

struct TimelineItem: Identifiable, Equatable, Codable {
    var id = UUID()
    var type: BlockType
    var startSec: Int
    var endSec: Int
    var tempo: TempoTarget
    var rampStart: Int?
    var rampEnd: Int?
}

enum CompileError: Error {
    case invalidDuration
    case invalidRepeat
    case invalidRamp
}

enum IntervalCompiler {
    static func compile(_ blocks: [Block]) throws -> [TimelineItem] {
        var out: [TimelineItem] = []
        var cursor = 0

        func emit(_ b: Block) throws {
            guard b.durationSec >= 0 else { throw CompileError.invalidDuration }
            let end = cursor + b.durationSec
            out.append(TimelineItem(type: b.type,
                                    startSec: cursor,
                                    endSec: end,
                                    tempo: b.tempo,
                                    rampStart: b.rampStart,
                                    rampEnd: b.rampEnd))
            cursor = end
        }

        func walk(_ list: [Block]) throws {
            for b in list {
                switch b.type {
                case .repeatGroup:
                    guard let n = b.repeatCount, n > 0, let subs = b.subblocks, !subs.isEmpty else {
                        throw CompileError.invalidRepeat
                    }
                    for _ in 0..<n { try walk(subs) }

                case .rampUp, .rampDown:
                    guard b.durationSec > 0, let rs = b.rampStart, let re = b.rampEnd else {
                        throw CompileError.invalidRamp
                    }
                    let _ = (rs, re) // used to enforce presence
                    try emit(b)

                default:
                    try emit(b)
                }
            }
        }

        try walk(blocks)
        return out
    }

    static func totalDuration(_ blocks: [Block]) -> Int {
        (try? compile(blocks).last?.endSec) ?? 0
    }
}
