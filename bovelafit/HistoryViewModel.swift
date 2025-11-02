import Foundation
import Combine

struct HistorySection: Identifiable, Equatable {
    let id = UUID()
    let day: Date
    let items: [Session]
}

final class HistoryViewModel: ObservableObject {
    @Published var dateFrom: Date? = nil
    @Published var dateTo: Date? = nil
    @Published var minRPE: Int? = nil
    @Published var maxRPE: Int? = nil

    func filter(_ sessions: [Session]) -> [Session] {
        sessions.filter { s in
            let inFrom = dateFrom.map { s.date >= startOfDay($0) } ?? true
            let inTo = dateTo.map { s.date <= endOfDay($0) } ?? true
            let rpeMinOK = minRPE.map { (s.rpe ?? 0) >= $0 } ?? true
            let rpeMaxOK = maxRPE.map { (s.rpe ?? 10) <= $0 } ?? true
            return inFrom && inTo && rpeMinOK && rpeMaxOK
        }
    }

    func sections(_ sessions: [Session]) -> [HistorySection] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: sessions) { s -> Date in
            cal.startOfDay(for: s.date)
        }
        let sortedDays = grouped.keys.sorted(by: >)
        return sortedDays.map { day in
            HistorySection(day: day, items: grouped[day]!.sorted { $0.date > $1.date })
        }
    }

    func totalTime(_ sessions: [Session]) -> Int {
        sessions.reduce(0) { $0 + $1.totalSec }
    }

    func averageRPE(_ sessions: [Session]) -> Double? {
        let rpes = sessions.compactMap { $0.rpe }
        guard !rpes.isEmpty else { return nil }
        let sum = rpes.reduce(0, +)
        return Double(sum) / Double(rpes.count)
    }

    func averageInZone(_ sessions: [Session]) -> Double? {
        let zs = sessions.compactMap { $0.inZonePercent }
        guard !zs.isEmpty else { return nil }
        let sum = zs.reduce(0.0, +)
        return sum / Double(zs.count)
    }

    private func startOfDay(_ d: Date) -> Date {
        Calendar.current.startOfDay(for: d)
    }

    private func endOfDay(_ d: Date) -> Date {
        let cal = Calendar.current
        let start = cal.startOfDay(for: d)
        return cal.date(byAdding: DateComponents(day: 1, second: -1), to: start) ?? d
    }
}
