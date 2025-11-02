import SwiftUI
import Combine

struct SettingsScreen: View {
    @EnvironmentObject private var haptics: HapticsManager
    @EnvironmentObject private var programs: ProgramRepository
    @EnvironmentObject private var sessions: SessionRepository
    @EnvironmentObject private var settings: SettingsViewModel
    @State private var showClearAlert = false
    @State private var showPrivacyAlert = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            List {
                hapticsSection
                visualsSection
                sessionBehaviorSection
                unitsSection
                dataSection
                privacySection
                // aboutSection
            }
            .navigationTitle("Settings")
            .onAppear { settings.apply(to: haptics) }
            .onChange(of: settings.hapticsEnabled) { _ in settings.apply(to: haptics) }
            .onChange(of: settings.hapticsIntensity) { _ in settings.apply(to: haptics) }
            .alert("Erase all history?", isPresented: $showClearAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Erase", role: .destructive) { sessions.clear() }
            } message: {
                Text("This action cannot be undone.")
            }
            .alert("Privacy", isPresented: $showPrivacyAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please accept the privacy policy to continue using analytics features.")
            }
        }
    }

    private var hapticsSection: some View {
        Section("Haptics") {
            Toggle("Enable Haptics", isOn: $settings.hapticsEnabled)
            Picker("Intensity", selection: $settings.hapticsIntensity) {
                Text("Low").tag(HapticsManager.Intensity.low)
                Text("Medium").tag(HapticsManager.Intensity.medium)
                Text("High").tag(HapticsManager.Intensity.high)
            }
            .pickerStyle(.segmented)
        }
    }

    private var visualsSection: some View {
        Section("Visuals") {
            Toggle("Tempo Pulse", isOn: $settings.visualPulseEnabled)
            Toggle("Out-of-Range Frame Warning", isOn: $settings.frameWarningEnabled)
            Stepper("Pre-countdown: \(settings.preCountdownSec) s", value: $settings.preCountdownSec, in: 0...10)
        }
    }

    private var sessionBehaviorSection: some View {
        Section("Session Controls") {
            Toggle("Compare With Target Tempo", isOn: $settings.compareTempoEnabled)
            Stepper("Seek step: \(settings.seekStepSec) s", value: $settings.seekStepSec, in: 1...60)
        }
    }

    private var unitsSection: some View {
        Section("Units") {
            Picker("Tempo Units", selection: $settings.tempoUnits) {
                Text("spm").tag("spm")
                Text("rpm").tag("rpm")
            }
            .pickerStyle(.segmented)
        }
    }

    private var dataSection: some View {
        Section("Data") {
            Button(role: .destructive) {
                showClearAlert = true
            } label: {
                Label("Erase All History", systemImage: AppIcons.delete)
            }
        }
    }

    private var privacySection: some View {
        Section("Privacy") {
            Button {
                if let url = URL(string: "https://www.termsfeed.com/live/a226d617-fe41-4a19-98a1-632d9b0d152e") {
                    openURL(url)
                }
            } label: {
                Label("Privacy Policy", systemImage: "shield.lefthalf.filled")
            }

//            HStack {
//                if let ts = settings.privacyAcceptedAt {
//                    Label("Accepted \(Formatters.date(ts))", systemImage: "checkmark.seal.fill")
//                        .foregroundStyle(ColorTokens.success)
//                } else {
//                    Label("Not accepted", systemImage: "exclamationmark.triangle.fill")
//                        .foregroundStyle(ColorTokens.warning)
//                }
//                Spacer()
//                Button(settings.privacyAcceptedAt == nil ? "Accept" : "Re-accept") {
//                    settings.acceptPrivacyNow()
//                }
//                .buttonStyle(.bordered)
//            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("App")
                Spacer()
                Text("bovelafit").foregroundStyle(.secondary)
            }
            HStack {
                Text("Version")
                Spacer()
                Text(appVersionString()).foregroundStyle(.secondary)
            }
            Toggle("Analytics (local only)", isOn: $settings.analyticsEnabled)
                .onChange(of: settings.analyticsEnabled) { enabled in
                    if enabled && settings.privacyAcceptedAt == nil {
                        settings.analyticsEnabled = false
                        showPrivacyAlert = true
                    }
                }
        }
    }

    private func appVersionString() -> String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}
