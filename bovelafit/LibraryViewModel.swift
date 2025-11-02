import Foundation
import Combine

final class LibraryViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var selectedTag: String? = nil

    func filter(_ items: [Program]) -> [Program] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return items.filter { p in
            let matchesQuery = q.isEmpty || p.name.localizedCaseInsensitiveContains(q)
            let matchesTag = selectedTag == nil || p.tags.contains(selectedTag!)
            return matchesQuery && matchesTag
        }
    }

    func totalDuration(of p: Program) -> Int {
        (try? IntervalCompiler.compile(p.blocks).last?.endSec) ?? 0
    }
}
