import Foundation
import Combine

final class PersistenceStore: ObservableObject {
    private let fm = FileManager.default

    private func url(_ name: String) -> URL {
        let dir = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent(name)
    }

    func save<T: Encodable>(_ value: T, as name: String) throws {
        let data = try JSONEncoder().encode(value)
        try data.write(to: url(name), options: .atomic)
    }

    func load<T: Decodable>(_ type: T.Type, from name: String, default def: T) -> T {
        let u = url(name)
        guard let data = try? Data(contentsOf: u) else { return def }
        return (try? JSONDecoder().decode(T.self, from: data)) ?? def
    }
}
