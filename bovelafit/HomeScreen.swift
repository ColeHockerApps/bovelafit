import SwiftUI
import Combine

struct HomeScreen: View {
    @EnvironmentObject private var haptics: HapticsManager
    @EnvironmentObject private var programs: ProgramRepository
    @StateObject private var vm = HomeViewModel()

    @State private var showRun = false
    @State private var runBlocks: [Block] = []

    var body: some View {
        NavigationStack {
            List {
                quickTempoSection
                    .listRowBackground(ColorTokens.surface2)

                if !programs.items.isEmpty {
                    Section("Recent Programs") {
                        ForEach(programs.items.prefix(3)) { p in
                            NavigationLink {
                                ProgramDetailView(program: p)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(p.name)
                                            .font(.headline)
                                        HStack(spacing: 8) {
                                            Image(systemName: "clock")
                                            Text(Formatters.time(totalDuration(p)))
                                        }
                                        .font(.subheadline)
                                        .foregroundStyle(ColorTokens.textSecondary)
                                    }
                                    Spacer()
                                }
                            }
                        }
                    }
                    .listRowBackground(ColorTokens.surface2)
                }
            }
            .scrollContentBackground(.hidden)
            .background(ColorTokens.bg.ignoresSafeArea())
            .navigationTitle("Home")
            .sheet(isPresented: $showRun) {
                RunSessionSheet(blocks: runBlocks)
            }
        }
        .tint(ColorTokens.accent)
    }

    private var quickTempoSection: some View {
        Section("Quick Tempo") {
            Picker("Mode", selection: $vm.quickTempoMode) {
                Text("None").tag(TempoMode.none)
                Text("Fixed").tag(TempoMode.fixed)
                Text("Range").tag(TempoMode.range)
            }
            .pickerStyle(.segmented)

            if vm.quickTempoMode == .fixed {
                Stepper("Target: \(vm.quickTempoFixed) spm",
                        value: $vm.quickTempoFixed, in: 40...300)
            } else if vm.quickTempoMode == .range {
                Stepper("Min: \(vm.quickTempoMin) spm",
                        value: $vm.quickTempoMin, in: 40...300)
                Stepper("Max: \(vm.quickTempoMax) spm",
                        value: $vm.quickTempoMax, in: 40...300)
            }

            Stepper("Duration: \(Formatters.time(vm.quickDuration))",
                    value: $vm.quickDuration, in: 60...7200, step: 60)

            Button {
                guard vm.validate() else { haptics.warning(); return }
                haptics.success()
                runBlocks = vm.quickBlocks()
                showRun = true
            } label: {
                Label("Start", systemImage: AppIcons.run)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func totalDuration(_ p: Program) -> Int {
        (try? IntervalCompiler.compile(p.blocks).last?.endSec) ?? 0
    }
}
