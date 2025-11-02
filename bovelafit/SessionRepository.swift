

import Foundation
import Combine

final class SessionRepository: ObservableObject {
    @Published private(set) var sessions: [Session] = []
    private let filename = "sessions.json"
    private var cancellables = Set<AnyCancellable>()
    private let store = PersistenceStore()

    init() {
        self.sessions = store.load([Session].self, from: filename, default: [])
        $sessions
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] arr in
                guard let self else { return }
                try? self.store.save(arr, as: self.filename)
            }
            .store(in: &cancellables)
    }

    func add(_ s: Session) { sessions.insert(s, at: 0) }
    func update(_ s: Session) { sessions.replaceAll(where: { $0.id == s.id }, with: s) }
    func remove(_ id: UUID) { sessions.removeAll { $0.id == id } }
    func clear() { sessions.removeAll() }
}

private extension Array {
    mutating func replaceAll(where predicate: (Element) -> Bool, with newValue: Element) {
        for i in indices where predicate(self[i]) { self[i] = newValue }
    }
}
