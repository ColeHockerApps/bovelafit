import Foundation
import Combine
import SwiftUI

final class SessionRunner: ObservableObject {
    @Published private(set) var totalSec: Int = 0
    @Published private(set) var elapsedSec: Int = 0
    @Published private(set) var currentIndex: Int = 0
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var current: TimelineItem?
    @Published var showEndSheet: Bool = false

    private var timeline: [TimelineItem] = []
    private var tickC: Cancellable?
    private var beatC: Cancellable?
    private var startAt: Date?
    private let haptics: HapticsManager

    init(haptics: HapticsManager) { self.haptics = haptics }

    func start(with blocks: [Block]) {
        guard let t = try? IntervalCompiler.compile(blocks), !t.isEmpty else { return }
        timeline = t
        totalSec = t.last!.endSec
        elapsedSec = 0
        currentIndex = 0
        current = t.first
        isRunning = true
        startAt = Date()
        haptics.blockChange()
        scheduleTick()
        scheduleBeats()
    }

    func start(with timelineItems: [TimelineItem]) {
        guard !timelineItems.isEmpty else { return }
        timeline = timelineItems
        totalSec = timelineItems.last!.endSec
        elapsedSec = 0
        currentIndex = 0
        current = timelineItems.first
        isRunning = true
        startAt = Date()
        haptics.blockChange()
        scheduleTick()
        scheduleBeats()
    }

    func pause() { isRunning = false; tickC?.cancel(); beatC?.cancel() }
    func resume() { guard !timeline.isEmpty else { return }; isRunning = true; scheduleTick(); scheduleBeats() }
    func end() { pause(); showEndSheet = true }

    func skip() {
        guard currentIndex + 1 < timeline.count else { end(); return }
        currentIndex += 1
        current = timeline[currentIndex]
        haptics.blockChange()
        scheduleBeats()
    }

    func seek(delta: Int) {
        let target = max(0, min(totalSec, elapsedSec + delta))
        elapsedSec = target
        advanceToElapsed()
        scheduleBeats()
    }

    private func scheduleTick() {
        tickC?.cancel()
        tickC = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, self.isRunning else { return }
                self.elapsedSec += 1
                self.advanceOnBoundary()
            }
    }

    private func scheduleBeats() {
        beatC?.cancel()
        guard isRunning, let cur = current else { return }
        let tempo = computedTempo(for: cur, at: elapsedSec)
        guard tempo > 0 else { return }
        let base = TempoEngine.interval(for: tempo)
        let pattern = TempoEngine.pattern(for: tempo)
        var counter = 0
        beatC = Timer.publish(every: base, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, self.isRunning else { return }
                let nowItem = self.current
                if nowItem?.id != cur.id { self.scheduleBeats(); return }
                switch pattern {
                case .direct:
                    self.haptics.tap()
                case .every(let n):
                    counter &+= 1
                    if counter % n == 0 { self.haptics.tap() }
                }
            }
    }

    private func advanceOnBoundary() {
        guard let cur = current else { return }
        if elapsedSec >= cur.endSec {
            if currentIndex + 1 < timeline.count {
                currentIndex += 1
                current = timeline[currentIndex]
                haptics.blockChange()
                scheduleBeats()
            } else {
                end()
            }
        }
    }

    private func advanceToElapsed() {
        guard !timeline.isEmpty else { return }
        if let idx = timeline.lastIndex(where: { $0.startSec <= elapsedSec }) {
            currentIndex = idx
            current = timeline[idx]
            haptics.blockChange()
        } else {
            currentIndex = 0
            current = timeline.first
        }
    }

    private func computedTempo(for item: TimelineItem, at second: Int) -> Int {
        switch item.type {
        case .rampUp, .rampDown:
            if let rs = item.rampStart, let re = item.rampEnd {
                let span = max(1, item.endSec - item.startSec)
                let pos = max(0, min(span, second - item.startSec))
                let p = Double(pos) / Double(span)
                return TempoEngine.rampValue(start: rs, end: re, progress01: p)
            }
            return TempoEngine.effectiveTempo(from: item.tempo)
        default:
            return TempoEngine.effectiveTempo(from: item.tempo)
        }
    }
}
