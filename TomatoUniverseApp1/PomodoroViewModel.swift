import SwiftUI
import Combine

@MainActor
final class PomodoroViewModel: ObservableObject {
    @Published var sets: [PomodoroSet] = [] { didSet { persist() } }
    private let storageKey = "pomodoroSets.v2"

    init() { load() }

    func createSet(title: String, targetNote: String?, targetDate: Date?) {
        sets.append(.make(title: title, targetNote: targetNote, targetDate: targetDate, total: 50))
    }

    func deleteSet(id: UUID) {
        sets.removeAll { $0.id == id }
    }

    func bindingForSet(id: UUID) -> Binding<PomodoroSet>? {
        guard let idx = sets.firstIndex(where: { $0.id == id }) else { return nil }
        return Binding(
            get: { self.sets[idx] },
            set: { self.sets[idx] = $0 }
        )
    }

    private func load() {
        let iso = JSONDecoder(); iso.dateDecodingStrategy = .iso8601
        let def = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: storageKey) {
            if let decoded = try? iso.decode([PomodoroSet].self, from: data) { sets = decoded; return }
            if let decoded = try? def.decode([PomodoroSet].self, from: data)  { sets = decoded; return }
        }
        sets = [
            .make(title: "Spanish", targetNote: "Understand daily conversation",
                  targetDate: .now.addingTimeInterval(TimeInterval(7 * 86400))),
            .make(title: "Reading", targetNote: "Finish 200 pages",
                  targetDate: .now.addingTimeInterval(TimeInterval(14 * 86400)))
        ]
        persist()
    }

    private func persist() {
        let enc = JSONEncoder(); enc.dateEncodingStrategy = .iso8601
        if let data = try? enc.encode(sets) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}

#if DEBUG
#Preview("ViewModel Snapshot") {
    VStack {
        Text("Sets: \(PreviewMocks.vm.sets.count)")
        Text(PreviewMocks.vm.sets.first?.title ?? "-")
    }
    .environmentObject(PreviewMocks.vm)
}
#endif
