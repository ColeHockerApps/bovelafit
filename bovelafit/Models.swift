import Foundation
import Combine

enum BlockType: String, Codable, CaseIterable {
    case warmup
    case work
    case recover
    case cooldown
    case rampUp
    case rampDown
    case repeatGroup
}

enum TempoMode: String, Codable {
    case none
    case fixed
    case range
}

struct TempoTarget: Codable, Equatable {
    var mode: TempoMode
    var value: Int?        // for fixed
    var min: Int?          // for range
    var max: Int?          // for range
}

struct Block: Identifiable, Codable, Equatable {
    var id = UUID()
    var type: BlockType
    var durationSec: Int
    var tempo: TempoTarget
    var repeatCount: Int?          // for repeatGroup
    var subblocks: [Block]?        // for repeatGroup
    var rampStart: Int?            // for rampUp/Down
    var rampEnd: Int?
}

struct Program: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var tags: [String]
    var blocks: [Block]
    var createdAt: Date
    var updatedAt: Date
}

struct BlockLog: Identifiable, Codable, Equatable {
    var id = UUID()
    var type: BlockType
    var target: TempoTarget
    var durationSec: Int
}

struct Session: Identifiable, Codable, Equatable {
    var id = UUID()
    var date: Date
    var programId: UUID?
    var quickName: String?
    var totalSec: Int
    var inZonePercent: Double?
    var rpe: Int?
    var note: String?
    var blocks: [BlockLog]
}
