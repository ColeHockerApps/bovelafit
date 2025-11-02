import Foundation
import Combine
import SwiftUI

final class BuilderViewModel: ObservableObject {
    @Published var name: String = "Custom Program"
    @Published var blocks: [Block] = []
    @Published var totalDuration: Int = 0
    @Published var validationError: String? = nil

    func addBlock(_ b: Block) {
        blocks.append(b)
        recalc()
    }

    func removeBlock(at offsets: IndexSet) {
        blocks.remove(atOffsets: offsets)
        recalc()
    }

    func moveBlock(from source: IndexSet, to destination: Int) {
        blocks.move(fromOffsets: source, toOffset: destination)
        recalc()
    }

    func recalc() {
        totalDuration = IntervalCompiler.totalDuration(blocks)
    }

    func buildProgram() -> Program {
        Program(
            id: UUID(),
            name: name,
            tags: [],
            blocks: blocks,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    func validate() -> Bool {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            validationError = "Name cannot be empty"
            return false
        }
        guard !blocks.isEmpty else {
            validationError = "Program must contain at least one block"
            return false
        }
        validationError = nil
        return true
    }

    func reset() {
        name = "Custom Program"
        blocks.removeAll()
        totalDuration = 0
        validationError = nil
    }
}
