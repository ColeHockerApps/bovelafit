import SwiftUI
import Combine

struct BlockTypePill: View {
    let type: BlockType
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(title)
        }
        .font(.caption)
        .foregroundStyle(ColorTokens.blockColor(type))
        .pillStyle(ColorTokens.blockColor(type))
    }

    private var title: String {
        switch type {
        case .warmup: return "Warmup"
        case .work: return "Work"
        case .recover: return "Recover"
        case .cooldown: return "Cooldown"
        case .rampUp: return "Ramp Up"
        case .rampDown: return "Ramp Down"
        case .repeatGroup: return "Repeat"
        }
    }

    private var icon: String {
        switch type {
        case .warmup: return "flame.fill"
        case .work: return "bolt.fill"
        case .recover: return "leaf.fill"
        case .cooldown: return "snowflake"
        case .rampUp: return "chart.line.uptrend.xyaxis"
        case .rampDown: return "chart.line.downtrend.xyaxis"
        case .repeatGroup: return "repeat"
        }
    }
}

struct ProgressBar: View {
    let progress: CGFloat
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(ColorTokens.surface2)
                RoundedRectangle(cornerRadius: 8)
                    .fill(ColorTokens.accentGradient)
                    .frame(width: max(0, min(geo.size.width, geo.size.width * progress)))
            }
        }
        .frame(height: 10)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct RunSessionSheet: View {
    @EnvironmentObject private var haptics: HapticsManager
    @EnvironmentObject private var settings: SettingsViewModel
    @StateObject private var runner: SessionRunner
    @Environment(\.dismiss) private var dismiss

    init(blocks: [Block]) {
        _runner = StateObject(wrappedValue: SessionRunner(haptics: HapticsManager()))
        self._inputBlocks = State(initialValue: blocks)
        self._inputTimeline = State(initialValue: [])
    }

    init(timeline: [TimelineItem]) {
        _runner = StateObject(wrappedValue: SessionRunner(haptics: HapticsManager()))
        self._inputBlocks = State(initialValue: [])
        self._inputTimeline = State(initialValue: timeline)
    }

    @State private var inputBlocks: [Block] = []
    @State private var inputTimeline: [TimelineItem] = []
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 20) {
            if let cur = runner.current {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        BlockTypePill(type: cur.type)
                        Spacer()
                        Text(Formatters.tempo(cur.tempo))
                            .foregroundStyle(ColorTokens.textSecondary)
                            .font(.subheadline)
                    }

                    HStack(alignment: .lastTextBaseline, spacing: 10) {
                        Text(timeLeft(cur))
                            .font(.system(size: 44, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white)
                            .scaleEffect(settings.visualPulseEnabled ? pulseScale : 1)
                        Text("remaining")
                            .foregroundStyle(ColorTokens.textSecondary)
                    }

                    ProgressBar(progress: totalProgress)
                        .frame(height: 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(ColorTokens.cardStroke, lineWidth: 0.5)
                        )
                }
                .cardStyle()
            }

            HStack(spacing: 14) {
                Button {
                    if runner.isRunning { runner.pause() } else { runner.resume() }
                } label: {
                    Label(runner.isRunning ? "Pause" : "Resume",
                          systemImage: runner.isRunning ? AppIcons.pause : AppIcons.run)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    runner.skip()
                } label: {
                    Label("Skip", systemImage: AppIcons.skip)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            Button(role: .destructive) {
                runner.end()
            } label: {
                Label("End Session", systemImage: AppIcons.stop)
            }
            .buttonStyle(.bordered)
            .padding(.top, 4)
        }
        .padding()
        .background(ColorTokens.bg.ignoresSafeArea())
        .onAppear {
            if !inputBlocks.isEmpty { runner.start(with: inputBlocks) }
            else if !inputTimeline.isEmpty { runner.start(with: inputTimeline) }
            if settings.visualPulseEnabled {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    pulseScale = 1.07
                }
            }
        }
        .onDisappear { runner.pause() }
        .sheet(isPresented: $runner.showEndSheet) {
            SessionEndSheet(onClose: { dismiss() })
        }
    }

    private var totalProgress: CGFloat {
        guard runner.totalSec > 0 else { return 0 }
        return CGFloat(runner.elapsedSec) / CGFloat(runner.totalSec)
    }

    private func timeLeft(_ cur: TimelineItem) -> String {
        let left = max(0, cur.endSec - runner.elapsedSec)
        return Formatters.time(left)
    }
}

struct SessionEndSheet: View {
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.seal.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80)
                .foregroundColor(ColorTokens.success)
            Text("Session Complete")
                .font(.title2)
                .bold()
            Button("Close") { onClose() }
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(ColorTokens.bg)
    }
}
