import SwiftUI
import Combine

struct BuilderScreen: View {
    @EnvironmentObject private var programs: ProgramRepository
    @EnvironmentObject private var haptics: HapticsManager
    @StateObject private var vm = BuilderViewModel()

    @State private var showAdd = false
    @State private var showRun = false
    @State private var runBlocks: [Block] = []

    var body: some View {
        NavigationStack {
            List {
                summaryCard
                    .listRowBackground(ColorTokens.surface2)
                    .listRowSeparator(.hidden)

                Section("Program") {
                    TextField("Name", text: $vm.name)
                        .textInputAutocapitalization(.words)
                }
                .listRowBackground(ColorTokens.surface2)

                Section("Blocks") {
                    if vm.blocks.isEmpty {
                        Text("No blocks yet").foregroundStyle(ColorTokens.textSecondary)
                    } else {
                        ForEach(vm.blocks.indices, id: \.self) { i in
                            BuilderBlockRow(block: vm.blocks[i])
                                .contentShape(Rectangle())
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        vm.removeBlock(at: IndexSet(integer: i))
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    Button {
                                        var copy = vm.blocks[i]
                                        copy.id = UUID()
                                        vm.addBlock(copy)
                                    } label: {
                                        Label("Duplicate", systemImage: "square.on.square")
                                    }
                                }
                        }
                        .onDelete(perform: vm.removeBlock)
                        .onMove(perform: vm.moveBlock)
                    }

                    Button {
                        showAdd = true
                    } label: {
                        Label("Add Block", systemImage: AppIcons.plus)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                }
                .listRowBackground(ColorTokens.surface2)

                if let err = vm.validationError {
                    Section {
                        Text(err).foregroundStyle(ColorTokens.error)
                    }
                    .listRowBackground(ColorTokens.surface2)
                }
            }
            .environment(\.defaultMinListRowHeight, 56)
            .scrollContentBackground(.hidden)
            .background(ColorTokens.bg.ignoresSafeArea())
            .navigationTitle("Builder")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button { showAdd = true } label: {
                        Image(systemName: AppIcons.plus) // add
                    }
                    Button {
                        guard vm.validate() else { haptics.warning(); return }
                        haptics.success()
                        let p = vm.buildProgram()
                        programs.add(p)
                    } label: {
                        Image(systemName: AppIcons.save) // save
                    }
                    Button {
                        guard vm.validate() else { haptics.warning(); return }
                        runBlocks = vm.blocks
                        showRun = true
                    } label: {
                        Image(systemName: AppIcons.run) // run
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddBlockSheet { newBlock in
                    vm.addBlock(newBlock)
                }
            }
            .sheet(isPresented: $showRun) {
                RunSessionSheet(blocks: runBlocks)
            }
            .onChange(of: vm.blocks) { _ in vm.recalc() }
        }
        .tint(ColorTokens.accent)
    }

    // MARK: - Summary

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Program Overview")
                    .font(.headline)
                Spacer()
                if vm.blocks.isEmpty == false {
                    Label("\(vm.blocks.count) blocks", systemImage: "square.grid.2x2")
                        .font(.subheadline)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
            }

            HStack(spacing: 12) {
                metricTile(title: "Total", value: Formatters.time(vm.totalDuration), icon: "clock", color: ColorTokens.info)
                metricTile(title: "Tempo Mode", value: dominantTempoMode(), icon: "metronome.fill", color: ColorTokens.accent)
            }
        }
        .cardStyle()
    }

    private func metricTile(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundStyle(ColorTokens.textSecondary)
                Text(value).font(.headline)
            }
            Spacer()
        }
        .padding(10)
        .background(ColorTokens.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ColorTokens.cardStroke, lineWidth: 0.5))
    }

    private func dominantTempoMode() -> String {
        let modes = vm.blocks.map { $0.tempo.mode }
        let fixed = modes.filter { $0 == .fixed }.count
        let range = modes.filter { $0 == .range }.count
        let none = modes.filter { $0 == .none }.count
        let maxV = max(fixed, max(range, none))
        switch maxV {
        case fixed: return "Fixed"
        case range: return "Range"
        default: return "None"
        }
    }
}

// MARK: - Row

private struct BuilderBlockRow: View {
    let block: Block

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(ColorTokens.blockColor(block.type))
                .frame(width: 6)
                .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    BlockTypePill(type: block.type)
                    if block.type == .repeatGroup, let n = block.repeatCount {
                        Label("x\(n)", systemImage: "repeat")
                            .font(.caption)
                            .foregroundStyle(ColorTokens.textSecondary)
                            .pillStyle(ColorTokens.blockColor(.repeatGroup))
                    }
                }

                HStack(spacing: 12) {
                    Label(Formatters.time(block.durationSec), systemImage: "clock")
                    Label(Formatters.tempo(block.tempo), systemImage: "metronome.fill")
                }
                .font(.subheadline)
                .foregroundStyle(ColorTokens.textSecondary)
            }

            Spacer()
        }
        .listRowBackground(ColorTokens.surface2)
    }
}

// MARK: - Add Block Sheet

private struct AddBlockSheet: View {
    var onCreate: (Block) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var type: BlockType = .work
    @State private var durationSec: Int = 60

    @State private var tempoMode: TempoMode = .fixed
    @State private var tempoFixed: Int = 170
    @State private var tempoMin: Int = 160
    @State private var tempoMax: Int = 180

    @State private var repeatCount: Int = 4
    @State private var subblocks: [Block] = []

    @State private var rampStart: Int = 150
    @State private var rampEnd: Int = 190

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Block Type", selection: $type) {
                        ForEach(BlockType.allCases, id: \.self) {
                            Text(label(for: $0)).tag($0)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Duration") {
                    Stepper("Seconds: \(durationSec)", value: $durationSec, in: 5...3600, step: 5)
                }

                if type == .rampUp || type == .rampDown {
                    Section("Ramp") {
                        Stepper("Start: \(rampStart) spm", value: $rampStart, in: 40...300)
                        Stepper("End: \(rampEnd) spm", value: $rampEnd, in: 40...300)
                    }
                }

                if type != .repeatGroup {
                    Section("Tempo") {
                        Picker("Mode", selection: $tempoMode) {
                            Text("None").tag(TempoMode.none)
                            Text("Fixed").tag(TempoMode.fixed)
                            Text("Range").tag(TempoMode.range)
                        }
                        .pickerStyle(.segmented)

                        if tempoMode == .fixed {
                            Stepper("Target: \(tempoFixed) spm", value: $tempoFixed, in: 40...300)
                        } else if tempoMode == .range {
                            Stepper("Min: \(tempoMin) spm", value: $tempoMin, in: 40...300)
                            Stepper("Max: \(tempoMax) spm", value: $tempoMax, in: 40...300)
                        }
                    }
                }

                if type == .repeatGroup {
                    Section("Repeat Group") {
                        Stepper("Repeat count: \(repeatCount)", value: $repeatCount, in: 1...50)
                        if subblocks.isEmpty {
                            Text("No inner blocks").foregroundStyle(.secondary)
                        } else {
                            ForEach(subblocks) { b in
                                HStack {
                                    Text(innerTitle(b))
                                    Spacer()
                                    Text(Formatters.time(b.durationSec))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .onDelete { idx in subblocks.remove(atOffsets: idx) }
                            .onMove { from, to in subblocks.move(fromOffsets: from, toOffset: to) }
                        }
                        Menu {
                            Button("Add Work") { subblocks.append(makeWork()) }
                            Button("Add Recover") { subblocks.append(makeRecover()) }
                            Button("Add Warmup") { subblocks.append(makeSimple(.warmup, 60)) }
                            Button("Add Cooldown") { subblocks.append(makeSimple(.cooldown, 60)) }
                        } label: {
                            Label("Add Inner Block", systemImage: AppIcons.plus)
                        }
                    }
                }
            }
            .navigationTitle("Add Block")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        let t = TempoTarget(
                            mode: tempoMode,
                            value: tempoMode == .fixed ? tempoFixed : nil,
                            min: tempoMode == .range ? tempoMin : nil,
                            max: tempoMode == .range ? tempoMax : nil
                        )

                        let block: Block
                        switch type {
                        case .repeatGroup:
                            block = Block(
                                id: UUID(),
                                type: .repeatGroup,
                                durationSec: 0,
                                tempo: TempoTarget(mode: .none, value: nil, min: nil, max: nil),
                                repeatCount: repeatCount,
                                subblocks: subblocks,
                                rampStart: nil,
                                rampEnd: nil
                            )
                        case .rampUp, .rampDown:
                            block = Block(
                                id: UUID(),
                                type: type,
                                durationSec: durationSec,
                                tempo: TempoTarget(mode: .range, value: nil, min: rampStart, max: rampEnd),
                                repeatCount: nil,
                                subblocks: nil,
                                rampStart: rampStart,
                                rampEnd: rampEnd
                            )
                        default:
                            block = Block(
                                id: UUID(),
                                type: type,
                                durationSec: durationSec,
                                tempo: t,
                                repeatCount: nil,
                                subblocks: nil,
                                rampStart: nil,
                                rampEnd: nil
                            )
                        }

                        onCreate(block)
                        dismiss()
                    } label: {
                        Label("Add", systemImage: "checkmark.circle.fill")
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        guard durationSec >= 0 else { return false }
        if type == .repeatGroup {
            return repeatCount > 0 && !subblocks.isEmpty
        }
        if type == .rampUp || type == .rampDown {
            return durationSec > 0 && rampStart >= 40 && rampEnd >= 40 && rampStart <= 300 && rampEnd <= 300
        }
        switch tempoMode {
        case .none: return true
        case .fixed: return (40...300).contains(tempoFixed)
        case .range: return (40...300).contains(tempoMin) && (40...300).contains(tempoMax) && tempoMin <= tempoMax
        }
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

    private func innerTitle(_ b: Block) -> String {
        switch b.type {
        case .work: return "Work \(Formatters.tempo(b.tempo))"
        case .recover: return "Recover"
        case .warmup: return "Warmup"
        case .cooldown: return "Cooldown"
        case .rampUp: return "Ramp Up"
        case .rampDown: return "Ramp Down"
        case .repeatGroup: return "Repeat Group"
        }
    }

    private func makeWork() -> Block {
        Block(type: .work, durationSec: 20,
              tempo: TempoTarget(mode: .fixed, value: 170, min: nil, max: nil),
              repeatCount: nil, subblocks: nil, rampStart: nil, rampEnd: nil)
    }

    private func makeRecover() -> Block {
        Block(type: .recover, durationSec: 10,
              tempo: TempoTarget(mode: .none, value: nil, min: nil, max: nil),
              repeatCount: nil, subblocks: nil, rampStart: nil, rampEnd: nil)
    }

    private func makeSimple(_ t: BlockType, _ sec: Int) -> Block {
        Block(type: t, durationSec: sec,
              tempo: TempoTarget(mode: .none, value: nil, min: nil, max: nil),
              repeatCount: nil, subblocks: nil, rampStart: nil, rampEnd: nil)
    }
}
