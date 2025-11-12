import SwiftUI
import PhotosUI

private enum PUI {
    static let cardSide: CGFloat = 170
    static let gridSpacing: CGFloat = 16
    static let gridPaddingH: CGFloat = 16
    static let topSpacer: CGFloat = 110
    static let bottomSpacer: CGFloat = 120
    static let tomatoImageName = UIK.icon
    static let bgImageName = UIK.bg
}

// نفس ستايل الشايلد (خلفية شفافة + حد خفيف) بزوايا 18
private struct ChildClearCardModifier: ViewModifier {
    let corner: CGFloat = 18
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(Color.white.opacity(0.12).blendMode(.multiply))
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 3)
            )
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
    }
}
private extension View { func childClearCard() -> some View { modifier(ChildClearCardModifier()) } }

private struct PomodoroCard: View {
    let title: String
    let done: Int
    let total: Int
    var body: some View {
        VStack(spacing: -30) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .padding(.top, 15)

            Spacer(minLength: -2)

            Image(PUI.tomatoImageName)
                .resizable()
                .scaledToFit()
                .frame(height: PUI.cardSide * 1.1)

            Spacer(minLength: 8)

            Text("\(done)/\(total)")
                .font(.subheadline)
                .monospacedDigit()
                .foregroundColor(.white.opacity(0.95))
                .padding(.bottom, 15)
        }
        .frame(width: PUI.cardSide, height: PUI.cardSide)
        .childClearCard() // ← بدل .glass() إلى نفس ستايل الشايلد
    }
}

// =========================
// Create Sheet (existing UI)
// =========================
private struct HabitFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: (_ name: String, _ note: String?, _ date: Date?) -> Void

    @State private var name = ""
    @State private var note = ""
    @State private var date = Date()
    @State private var showCalendar = false
    @FocusState private var focusName: Bool

    var body: some View {
        VStack(spacing: 16) {
            Capsule().fill(Color.secondary.opacity(0.25)).frame(width: 48, height: 5).padding(.top, 10)
            Text("New Habit").font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Habit name")
                TextField("Example...", text: $name)
                    .textInputAutocapitalization(.sentences)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .focused($focusName)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Habit target (tomatoes)")
                TextField("Ex.. To understand daily Spanish conversation", text: $note)
                    .textInputAutocapitalization(.sentences)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Target date")
                Button { showCalendar = true } label: {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .sheet(isPresented: $showCalendar) {
                    VStack(spacing: 12) {
                        Text("Select Target Date").font(.headline).padding(.top, 20)
                        DatePicker("", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .frame(height: 300)
                            .padding(.horizontal, 16)
                        Button("Done") { showCalendar = false }.padding(.vertical, 8)
                    }
                    .presentationDetents([.medium, .large])
                }
            }

            Button {
                let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                let cleanNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
                onSave(cleanName.isEmpty ? "Untitled" : cleanName,
                       cleanNote.isEmpty ? nil : cleanNote,
                       date)
                dismiss()
            } label: {
                Label("Save", systemImage: "checkmark.circle.fill")
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .padding(.horizontal, 12).padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .clipShape(Capsule())

            Spacer(minLength: 8)
        }
        .padding(16)
        .background(Color(UIColor.systemMint).opacity(0.08))
        .onAppear { focusName = true }
    }
}

// ========================
// Edit Sheet (new for you)
// ========================
private struct HabitEditSheet: View {
    @Environment(\.dismiss) private var dismiss

    let initialName: String
    let initialNote: String?
    let initialDate: Date?
    var onSave: (_ name: String, _ note: String?, _ date: Date?) -> Void

    @State private var name: String
    @State private var note: String
    @State private var date: Date
    @State private var showCalendar = false
    @FocusState private var focusName: Bool

    init(initialName: String, initialNote: String?, initialDate: Date?, onSave: @escaping (_ name: String, _ note: String?, _ date: Date?) -> Void) {
        self.initialName = initialName
        self.initialNote = initialNote
        self.initialDate = initialDate
        self.onSave = onSave
        _name = State(initialValue: initialName)
        _note = State(initialValue: initialNote ?? "")
        _date = State(initialValue: initialDate ?? Date())
    }

    var body: some View {
        VStack(spacing: 16) {
            Capsule().fill(Color.secondary.opacity(0.25)).frame(width: 48, height: 5).padding(.top, 8)
            Text("Edit Habit").font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Habit name")
                TextField("Example...", text: $name)
                    .textInputAutocapitalization(.sentences)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .focused($focusName)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Habit target (tomatoes)")
                TextField("Ex.. To understand daily Spanish conversation", text: $note)
                    .textInputAutocapitalization(.sentences)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Target date")
                Button { showCalendar = true } label: {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .sheet(isPresented: $showCalendar) {
                    VStack(spacing: 12) {
                        Text("Select Target Date").font(.headline).padding(.top, 20)
                        DatePicker("", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .frame(height: 300)
                            .padding(.horizontal, 16)
                        Button("Done") { showCalendar = false }.padding(.vertical, 8)
                    }
                    .presentationDetents([.medium, .large])
                }
            }

            Button {
                let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                let cleanNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
                onSave(cleanName.isEmpty ? "Untitled" : cleanName,
                       cleanNote.isEmpty ? nil : cleanNote,
                       date)
                dismiss()
            } label: {
                Label("Save changes", systemImage: "checkmark.circle.fill")
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .padding(.horizontal, 12).padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .clipShape(Capsule())

            Spacer(minLength: 8)
        }
        .padding(16)
        .background(Color(UIColor.systemMint).opacity(0.08))
        .onAppear { focusName = true }
    }
}

struct Pomodoros: View {
    @EnvironmentObject private var vm: PomodoroViewModel
    @State private var showCreate = false
    @State private var pendingDelete: PomodoroSet? = nil
    @State private var showDeleteAlert = false

    // NEW: edit states
    @State private var pendingEdit: PomodoroSet? = nil
    @State private var showEdit = false

    var body: some View {
        ZStack {
            Image(PUI.bgImageName).resizable().scaledToFill().ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: PUI.topSpacer)

                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: PUI.cardSide), spacing: PUI.gridSpacing)],
                        spacing: PUI.gridSpacing
                    ) {
                        ForEach(vm.sets) { set in
                            NavigationLink {
                                if let binding = vm.bindingForSet(id: set.id) {
                                    PomodoroChildView(set: binding, totalCount: set.items.count)
                                        .toolbar(.hidden, for: .tabBar)
                                }
                            } label: {
                                PomodoroCard(title: set.title, done: set.doneCount, total: set.items.count)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button {
                                    pendingEdit = set
                                    showEdit = true
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }

                                Button(role: .destructive) {
                                    pendingDelete = set; showDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }

                        Button { showCreate = true } label: {
                            VStack(spacing: 0) {
                                Text("create one..")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.top, 10)
                                Spacer(minLength: 6)
                                Image(systemName: "plus")
                                    .font(.system(size: 34, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer(minLength: 6)
                                Text("0/50")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.95))
                                    .padding(.bottom, 10)
                            }
                            .frame(width: PUI.cardSide, height: PUI.cardSide)
                            .childClearCard() // ← نفس ستايل الشايلد
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, PUI.gridPaddingH)
                    .padding(.bottom, PUI.bottomSpacer)
                }
            }
        }
        .navigationTitle("Pomodoros")
        .navigationBarTitleDisplayMode(.inline)

        // Create
        .sheet(isPresented: $showCreate) {
            HabitFormSheet { name, note, date in
                vm.createSet(title: name, targetNote: note, targetDate: date)
            }
            .presentationDetents([.medium, .large])
            .presentationCornerRadius(28)
        }

        // Edit (prefilled)
        .sheet(isPresented: $showEdit) {
            if let s = pendingEdit {
                HabitEditSheet(
                    initialName: s.title,
                    initialNote: s.targetNote,
                    initialDate: s.targetDate
                ) { newName, newNote, newDate in
                    if let binding = vm.bindingForSet(id: s.id) {
                        var copy = binding.wrappedValue
                        copy.title = newName
                        copy.targetNote = newNote
                        copy.targetDate = newDate
                        binding.wrappedValue = copy
                    }
                }
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(28)
            }
        }

        // Delete
        .alert("Delete habit?", isPresented: $showDeleteAlert, presenting: pendingDelete) { set in
            Button("Delete", role: .destructive) { vm.deleteSet(id: set.id) }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: { set in
            Text("This will remove “\(set.title)”. This action can’t be undone.")
        }
    }
}

#if DEBUG
#Preview("Pomodoros") {
    NavigationStack {
        Pomodoros()
            .navigationTitle("Pomodoros")
            .navigationBarTitleDisplayMode(.inline)
    }
    .environmentObject(PreviewMocks.vm)
}
#endif
