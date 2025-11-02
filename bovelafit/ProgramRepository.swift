import Foundation
import Combine

final class ProgramRepository: ObservableObject {
    @Published private(set) var items: [Program] = []
    private let filename = "programs.json"
    private var cancellables = Set<AnyCancellable>()
    private let store = PersistenceStore()

    init() {
        self.items = store.load([Program].self, from: filename, default: Self.defaultPrograms())
        $items
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] arr in
                guard let self else { return }
                try? self.store.save(arr, as: self.filename)
            }
            .store(in: &cancellables)
    }

    func add(_ p: Program) { items.append(p) }
    func update(_ p: Program) { items.replaceAll(where: { $0.id == p.id }, with: p) }
    func remove(_ id: UUID) { items.removeAll { $0.id == id } }
    func byId(_ id: UUID) -> Program? { items.first { $0.id == id } }

    private static func defaultPrograms() -> [Program] {
        let work = Block(type: .work,
                         durationSec: 20,
                         tempo: TempoTarget(mode: .fixed, value: 170, min: nil, max: nil),
                         repeatCount: nil,
                         subblocks: nil,
                         rampStart: nil,
                         rampEnd: nil)
        let rest = Block(type: .recover,
                         durationSec: 10,
                         tempo: TempoTarget(mode: .none, value: nil, min: nil, max: nil),
                         repeatCount: nil,
                         subblocks: nil,
                         rampStart: nil,
                         rampEnd: nil)
        let tabata = Block(type: .repeatGroup,
                           durationSec: 0,
                           tempo: TempoTarget(mode: .none, value: nil, min: nil, max: nil),
                           repeatCount: 8,
                           subblocks: [work, rest],
                           rampStart: nil,
                           rampEnd: nil)
        let p = Program(id: UUID(),
                        name: "Tabata 8x20/10",
                        tags: ["hiit"],
                        blocks: [tabata],
                        createdAt: Date(),
                        updatedAt: Date())
        return [p]
    }
}

private extension Array {
    mutating func replaceAll(where predicate: (Element) -> Bool, with newValue: Element) {
        for i in indices where predicate(self[i]) { self[i] = newValue }
    }
}
