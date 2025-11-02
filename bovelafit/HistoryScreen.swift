import SwiftUI
import Combine

struct HistoryScreen: View {
    @EnvironmentObject private var sessionsRepo: SessionRepository
    @StateObject private var vm = HistoryViewModel()

    var body: some View {
        NavigationStack {
            List {
                if groups.isEmpty {
                    Text("No sessions yet").foregroundStyle(.secondary)
                } else {
                    ForEach(groups) { section in
                        Section(header: Text(sectionTitle(section.day))) {
                            ForEach(section.items) { s in
                                NavigationLink {
                                    SessionDetailView(session: s)
                                } label: {
                                    HistoryRow(session: s)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("Min RPE", selection: Binding(
                            get: { vm.minRPE ?? 0 },
                            set: { vm.minRPE = $0 == 0 ? nil : $0 }
                        )) {
                            Text("Any").tag(0)
                            ForEach(1...10, id: \.self) { Text("\($0)").tag($0) }
                        }
                        Picker("Max RPE", selection: Binding(
                            get: { vm.maxRPE ?? 0 },
                            set: { vm.maxRPE = $0 == 0 ? nil : $0 }
                        )) {
                            Text("Any").tag(0)
                            ForEach(1...10, id: \.self) { Text("\($0)").tag($0) }
                        }
                        DatePicker("From", selection: Binding(get: {
                            vm.dateFrom ?? Date()
                        }, set: { vm.dateFrom = $0 }), displayedComponents: .date)
                        .labelsHidden()
                        DatePicker("To", selection: Binding(get: {
                            vm.dateTo ?? Date()
                        }, set: { vm.dateTo = $0 }), displayedComponents: .date)
                        .labelsHidden()
                        Button("Clear Filters") {
                            vm.dateFrom = nil
                            vm.dateTo = nil
                            vm.minRPE = nil
                            vm.maxRPE = nil
                        }
                    } label: {
                        Label("Filters", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }

    private var groups: [HistorySection] {
        let filtered = vm.filter(sessionsRepo.sessions)
        return vm.sections(filtered)
    }

    private func sectionTitle(_ day: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df.string(from: day)
    }
}

private struct HistoryRow: View {
    let session: Session

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(ColorTokens.info)
                    Text(title).font(.headline)
                }
                HStack(spacing: 10) {
                    Text(Formatters.time(session.totalSec))
                    if let r = session.rpe { Text("RPE \(r)") }
                    if let z = session.inZonePercent { Text(Formatters.percent(z)) }
                }
                .foregroundStyle(ColorTokens.textSecondary)
                .font(.subheadline)
            }
            Spacer()
            Text(timeStamp)
                .foregroundStyle(ColorTokens.textSecondary)
                .font(.caption)
        }
        .listRowBackground(ColorTokens.surface2)
    }

    private var title: String {
        if let name = session.quickName { return name }
        return "Program"
    }

    private var timeStamp: String {
        Formatters.date(session.date)
    }
}

struct SessionDetailView: View {
    @EnvironmentObject private var sessionsRepo: SessionRepository
    let session: Session

    var body: some View {
        List {
            Section("Overview") {
                row("Date", Formatters.date(session.date))
                row("Total", Formatters.time(session.totalSec))
                if let r = session.rpe { row("RPE", "\(r)") }
                if let z = session.inZonePercent { row("In-Zone", Formatters.percent(z)) }
                if let note = session.note, !note.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Note").font(.subheadline)
                        Text(note)
                    }
                }
            }

            Section("Blocks") {
                ForEach(session.blocks) { b in
                    HStack {
                        Text(label(for: b.type))
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(Formatters.time(b.durationSec))
                                .foregroundStyle(.secondary)
                            Text(Formatters.tempo(b.target))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Session")
    }

    @ViewBuilder
    private func row(_ l: String, _ r: String) -> some View {
        HStack {
            Text(l)
            Spacer()
            Text(r).foregroundStyle(.secondary)
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
}
