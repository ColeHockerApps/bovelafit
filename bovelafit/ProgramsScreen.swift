import SwiftUI
import Combine

struct ProgramsScreen: View {
    @EnvironmentObject private var programs: ProgramRepository
    @StateObject private var vm = LibraryViewModel()

    var body: some View {
        NavigationStack {
            List {
                if filtered.isEmpty {
                    Text("No programs yet").foregroundStyle(.secondary)
                } else {
                    ForEach(filtered) { p in
                        NavigationLink {
                            ProgramDetailView(program: p)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(p.name).font(.headline)
                                Text("Duration \(Formatters.time(totalDuration(of: p)))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete { idx in
                        for i in idx { programs.remove(filtered[i].id) }
                    }
                }
            }
            .searchable(text: $vm.query, placement: .automatic, prompt: "Search")
            .navigationTitle("Programs")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Tabata 8x20/10") { duplicateDefault("Tabata 8x20/10") }
                        Button("30/30 x10") { addThirtyThirty() }
                        Button("Pyramid 1–4–1") { addPyramid() }
                    } label: {
                        Label("Templates", systemImage: "plus")
                    }
                }
            }
        }
    }

    private var filtered: [Program] {
        vm.filter(programs.items)
    }

    private func totalDuration(of p: Program) -> Int {
        vm.totalDuration(of: p)
    }

    private func duplicateDefault(_ name: String) {
        guard let p = programs.items.first(where: { $0.name == name }) else { return }
        var copy = p
        copy.id = UUID()
        copy.name = "\(p.name) Copy"
        copy.createdAt = Date()
        copy.updatedAt = Date()
        programs.add(copy)
    }

    private func addThirtyThirty() {
        let w = Block(type: .work, durationSec: 30,
                      tempo: TempoTarget(mode: .fixed, value: 180, min: nil, max: nil),
                      repeatCount: nil, subblocks: nil, rampStart: nil, rampEnd: nil)
        let r = Block(type: .recover, durationSec: 30,
                      tempo: TempoTarget(mode: .none, value: nil, min: nil, max: nil),
                      repeatCount: nil, subblocks: nil, rampStart: nil, rampEnd: nil)
        let group = Block(type: .repeatGroup, durationSec: 0,
                          tempo: TempoTarget(mode: .none, value: nil, min: nil, max: nil),
                          repeatCount: 10, subblocks: [w, r], rampStart: nil, rampEnd: nil)
        let p = Program(name: "30/30 x10", tags: ["interval"], blocks: [group], createdAt: Date(), updatedAt: Date())
        programs.add(p)
    }

    private func addPyramid() {
        func work(_ sec: Int, _ spm: Int) -> Block {
            Block(type: .work, durationSec: sec,
                  tempo: TempoTarget(mode: .fixed, value: spm, min: nil, max: nil),
                  repeatCount: nil, subblocks: nil, rampStart: nil, rampEnd: nil)
        }
        let seq = [work(60, 160), work(60, 170), work(60, 180), work(60, 170), work(60, 160)]
        let p = Program(name: "Pyramid 1–4–1", tags: ["ladder"], blocks: seq, createdAt: Date(), updatedAt: Date())
        programs.add(p)
    }
}

struct ProgramDetailView: View {
    @EnvironmentObject private var programs: ProgramRepository
    @EnvironmentObject private var haptics: HapticsManager
    let program: Program

    @State private var showRun = false
    @State private var runTimeline: [TimelineItem] = []

    var body: some View {
        List {
            Section("Overview") {
                HStack {
                    Text("Total Duration")
                    Spacer()
                    Text(Formatters.time(total)).foregroundStyle(.secondary)
                }
                if !program.tags.isEmpty {
                    HStack {
                        Text("Tags")
                        Spacer()
                        Text(program.tags.joined(separator: ", ")).foregroundStyle(.secondary)
                    }
                }
            }
            Section("Blocks") {
                ForEach(compiled) { item in
                    HStack {
                        BlockTypePill(type: item.type)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(Formatters.time(item.endSec - item.startSec))
                                .foregroundStyle(ColorTokens.textSecondary)
                            Text(Formatters.tempo(item.tempo))
                                .font(.caption)
                                .foregroundStyle(ColorTokens.textSecondary)
                        }
                    }
                    .listRowBackground(ColorTokens.surface2)
                }
            }
            Section {
                Button {
                    haptics.success()
                    runTimeline = compiled
                    showRun = true
                } label: {
                    Label("Run", systemImage: AppIcons.run)
                }
            }
        }
        .navigationTitle(program.name)
        .sheet(isPresented: $showRun) {
            RunSessionSheet(timeline: runTimeline)
        }
    }

    private var compiled: [TimelineItem] {
        (try? IntervalCompiler.compile(program.blocks)) ?? []
    }

    private var total: Int {
        compiled.last?.endSec ?? 0
    }

    private func label(for t: BlockType) -> String {
        switch t {
        case .warmup: return "Warmup"
        case .work: return "Work"
        case .recover: return "Recover"
        case .cooldown: return "Cooldown"
        case .rampUp: return "Ramp Up"
        case .rampDown: return "Ramp Down"
        case .repeatGroup: return "Repeat Group"
        }
    }
}
