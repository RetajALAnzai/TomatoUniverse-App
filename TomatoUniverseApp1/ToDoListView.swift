import SwiftUI

struct ToDoItem: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var dueDate: Date
    var isDone: Bool
}

struct ToDoRow: View {
    @Binding var item: ToDoItem
    var textColor: Color = .white   // مناسب على bg2

    var body: some View {
        HStack(spacing: 12) {
            Button { item.isDone.toggle() } label: {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(textColor.opacity(item.isDone ? 0.95 : 0.9))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .foregroundColor(textColor)
                    .strikethrough(item.isDone, color: textColor.opacity(0.6))

                Text(item.dueDate, style: .date)
                    .font(.footnote)
                    .foregroundColor(textColor.opacity(0.85))
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        // 👇 قزاز قريب من حق الهوم
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.10).blendMode(.multiply))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1.5)
        )
    }
}

struct ToDoListView: View {
    // مصفوفة المهام الداخلية لواجهة التودو
    @State private var items: [ToDoItem] = [
        .init(title: "Buy water",     dueDate: .now, isDone: false),
        .init(title: "Read 10 pages", dueDate: .now.addingTimeInterval(86400), isDone: false),
        .init(title: "Gym session",   dueDate: .now, isDone: true)
    ]
    @State private var showAdd = false

    var textColor: Color = .white

    // نفس المفتاح اللي يستخدمه TUToDoFeed في الهوم
    private let storageKey = "TU.todo.items"

    // 👇 تحميل من التخزين ومزامنة مع ToDoLite اللي يستخدمه الهوم
    private func loadFromStorage() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let arr  = try? JSONDecoder().decode([ToDoLite].self, from: data) {
            items = arr.map { lite in
                ToDoItem(
                    title: lite.title,
                    dueDate: lite.due ?? .now,
                    isDone: false   // حالة الإنجاز ما نخزنها، مو ضرورية للهوم
                )
            }
        }
    }

    // 👇 حفظ إلى التخزين + إشعار الهوم بالتحديث
    private func saveToStorage() {
        let simple = items.map { todo in
            ToDoLite(title: todo.title, due: todo.dueDate)
        }

        if let data = try? JSONEncoder().encode(simple) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }

        // نخلي TUToDoFeed في الهوم يعيد load()
        NotificationCenter.default.post(name: .TUToDoItemsUpdated, object: nil)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Image("bg2").resizable().scaledToFill().ignoresSafeArea()

                VStack(spacing: 55) {
                    Spacer(minLength: 55)

                    List {
                        ForEach($items) { $item in
                            ToDoRow(item: $item, textColor: textColor)
                                .listRowBackground(Color.clear)
                        }
                        .onDelete { offsets in
                            items.remove(atOffsets: offsets)
                            saveToStorage()   // 🗑️ إذا حذفنا → حدث الهوم
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.plain)

                    Button { showAdd = true } label: {
                        Label("Add New Task", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 18)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.10).blendMode(.multiply))   // نفس درجة القزاز
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.18), lineWidth: 1.5)      // نفس البوردر حق الكروت
                            )
                    }
                    .padding(.bottom, 140)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.clear, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // action
                    } label: {
                        Image(systemName: "exclamationmark.circle")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddTaskSheet(onSave: { title, date in
                    items.append(.init(title: title, dueDate: date, isDone: false))
                    saveToStorage()   // ➕ إذا أضفنا → حدث الهوم
                }, textColor: textColor)
            }
            .onAppear {
                // لو فيه قائمة قديمة مخزّنة نحمّلها بدل الديفولت
                loadFromStorage()
            }
        }
    }
}

private struct AddTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var reminderDate: Date = .now
    @State private var enableReminder = false
    var onSave: (String, Date) -> Void
    var textColor: Color

    var body: some View {
        VStack(spacing: 16) {
            Capsule().fill(Color.secondary.opacity(0.25)).frame(width: 48, height: 5).padding(.top, 8)
            Text("New To-Do").font(.title3.bold())

            TextField("Write your task...", text: $title)
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled(true)
                .keyboardType(.asciiCapable)
                .font(.body)
                .padding(10)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Toggle("Reminder", isOn: $enableReminder).tint(.accentColor)

            if enableReminder {
                DatePicker("", selection: $reminderDate, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                let name = title.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else { return }
                onSave(name, reminderDate)
                dismiss()
            } label: {
                Text("Save Task")
                    .font(.headline).foregroundColor(.white)
                    .padding(.vertical, 10).padding(.horizontal, 18)
                    .background(Color.accentColor).clipShape(Capsule())
            }
            Spacer(minLength: 8)
        }
        .padding(20)
        .background(Color(UIColor.systemMint).opacity(0.08))
    }
}

#if DEBUG
#Preview("To-Do") {
    // ملاحظة: ToDoLite و Notification.Name.TUToDoItemsUpdated لازم يكونون معرّفين في المشروع
    ToDoListView()
}
#endif
