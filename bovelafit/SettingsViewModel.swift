import Foundation
import Combine

final class SettingsViewModel: ObservableObject {
    @Published var hapticsEnabled: Bool = true
    @Published var hapticsIntensity: HapticsManager.Intensity = .medium
    @Published var visualPulseEnabled: Bool = true
    @Published var frameWarningEnabled: Bool = true
    @Published var compareTempoEnabled: Bool = false
    @Published var seekStepSec: Int = 10
    @Published var preCountdownSec: Int = 3
    @Published var tempoUnits: String = "spm"
    @Published var privacyAcceptedAt: Date? = nil
    @Published var analyticsEnabled: Bool = false

    private var bag = Set<AnyCancellable>()
    private let defaults = UserDefaults.standard

    init() {
        load()
        setupAutoSave()
    }

    func apply(to haptics: HapticsManager) {
        haptics.enabled = hapticsEnabled
        haptics.intensity = hapticsIntensity
    }

    func acceptPrivacyNow() {
        privacyAcceptedAt = Date()
    }

    private func setupAutoSave() {
        let pubs: [AnyPublisher<Void, Never>] = [
            $hapticsEnabled.dropFirst().map { _ in () }.eraseToAnyPublisher(),
            $hapticsIntensity.dropFirst().map { _ in () }.eraseToAnyPublisher(),
            $visualPulseEnabled.dropFirst().map { _ in () }.eraseToAnyPublisher(),
            $frameWarningEnabled.dropFirst().map { _ in () }.eraseToAnyPublisher(),
            $compareTempoEnabled.dropFirst().map { _ in () }.eraseToAnyPublisher(),
            $seekStepSec.dropFirst().map { _ in () }.eraseToAnyPublisher(),
            $preCountdownSec.dropFirst().map { _ in () }.eraseToAnyPublisher(),
            $tempoUnits.dropFirst().map { _ in () }.eraseToAnyPublisher(),
            $privacyAcceptedAt.dropFirst().map { _ in () }.eraseToAnyPublisher(),
            $analyticsEnabled.dropFirst().map { _ in () }.eraseToAnyPublisher()
        ]

        Publishers.MergeMany(pubs)
            .sink { [weak self] in self?.save() }
            .store(in: &bag)
    }

    private func load() {
        if defaults.object(forKey: K.hapticsEnabled) != nil {
            hapticsEnabled = defaults.bool(forKey: K.hapticsEnabled)
        }
        if let raw = defaults.string(forKey: K.hapticsIntensity),
           let val = IntensityRaw(rawValue: raw)?.toIntensity {
            hapticsIntensity = val
        }
        visualPulseEnabled = defaults.object(forKey: K.visualPulseEnabled).map { _ in defaults.bool(forKey: K.visualPulseEnabled) } ?? true
        frameWarningEnabled = defaults.object(forKey: K.frameWarningEnabled).map { _ in defaults.bool(forKey: K.frameWarningEnabled) } ?? true
        compareTempoEnabled = defaults.bool(forKey: K.compareTempoEnabled)
        let step = defaults.integer(forKey: K.seekStepSec)
        seekStepSec = step == 0 ? 10 : step
        let pre = defaults.integer(forKey: K.preCountdownSec)
        preCountdownSec = pre == 0 ? 3 : pre
        tempoUnits = defaults.string(forKey: K.tempoUnits) ?? "spm"
        if let ts = defaults.object(forKey: K.privacyAcceptedAt) as? TimeInterval {
            privacyAcceptedAt = Date(timeIntervalSince1970: ts)
        }
        analyticsEnabled = defaults.bool(forKey: K.analyticsEnabled)
    }

    private func save() {
        defaults.set(hapticsEnabled, forKey: K.hapticsEnabled)
        defaults.set(IntensityRaw.from(hapticsIntensity).rawValue, forKey: K.hapticsIntensity)
        defaults.set(visualPulseEnabled, forKey: K.visualPulseEnabled)
        defaults.set(frameWarningEnabled, forKey: K.frameWarningEnabled)
        defaults.set(compareTempoEnabled, forKey: K.compareTempoEnabled)
        defaults.set(seekStepSec, forKey: K.seekStepSec)
        defaults.set(preCountdownSec, forKey: K.preCountdownSec)
        defaults.set(tempoUnits, forKey: K.tempoUnits)
        if let d = privacyAcceptedAt {
            defaults.set(d.timeIntervalSince1970, forKey: K.privacyAcceptedAt)
        }
        defaults.set(analyticsEnabled, forKey: K.analyticsEnabled)
    }

    private enum K {
        static let hapticsEnabled = "settings.hapticsEnabled"
        static let hapticsIntensity = "settings.hapticsIntensity"
        static let visualPulseEnabled = "settings.visualPulseEnabled"
        static let frameWarningEnabled = "settings.frameWarningEnabled"
        static let compareTempoEnabled = "settings.compareTempoEnabled"
        static let seekStepSec = "settings.seekStepSec"
        static let preCountdownSec = "settings.preCountdownSec"
        static let tempoUnits = "settings.tempoUnits"
        static let privacyAcceptedAt = "settings.privacyAcceptedAt"
        static let analyticsEnabled = "settings.analyticsEnabled"
    }

    private enum IntensityRaw: String {
        case low, medium, high

        var toIntensity: HapticsManager.Intensity {
            switch self {
            case .low: return .low
            case .medium: return .medium
            case .high: return .high
            }
        }

        static func from(_ i: HapticsManager.Intensity) -> IntensityRaw {
            switch i {
            case .low: return .low
            case .medium: return .medium
            case .high: return .high
            }
        }
    }
}
