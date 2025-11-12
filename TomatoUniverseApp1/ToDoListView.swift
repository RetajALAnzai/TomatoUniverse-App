import SwiftUI

// MARK: - نموذج المهمة
struct ToDoItem: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var dueDate: Date
    var isDone: Bool
}

// MARK: - صف واحد في القائمة
struct ToDoRow: View {
    @Binding var item: ToDoItem
    var textColor: Color = .black

    var body: some View {
        HStack(spacing: 12) {
            Button {
                item.isDone.toggle()
            } label: {
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
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(.white.opacity(0.22), lineWidth: 1)
        )
    }
}

// MARK: - نافذة إضافة مهمة (زجاجية + Reminder يحتوي تاريخ ووقت فقط)
struct AddTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var reminderDate: Date = .now
    @State private var enableReminder = false
    @State private var showHelp = false

    var onSave: (String, Date) -> Void
    var textColor: Color

    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()

            VStack(spacing: 16) {
                // العنوان العلوي
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.backward.circle.fill")
                            .font(.title2)
                            .foregroundColor(textColor)
                    }
                    Spacer()
                    Text("New To-Do")
                        .font(.title2.bold())
                        .foregroundColor(textColor)
                    Spacer()
                    Button { showHelp = true } label: {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.yellow)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    // Task Field
                    Text("Task")
                        .foregroundColor(textColor.opacity(0.9))

                    TextField("Write your task...", text: $title)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled(true)
                        .keyboardType(.asciiCapable)
                        .environment(\.layoutDirection, .leftToRight)
                        .font(.body)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Reminder section
                    Toggle("Reminder", isOn: $enableReminder)
                        .tint(.accentColor)

                    if enableReminder {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 12) {
                                DatePicker("Select date & time",
                                           selection: $reminderDate,
                                           displayedComponents: [.date, .hourAndMinute])
                                    .labelsHidden()
                                    .tint(textColor)
                            }
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            // عرض التاريخ والوقت المختارين
                            Text("Selected: \(reminderDate.formatted(date: .abbreviated, time: .shortened))")
                                .font(.footnote)
                                .foregroundColor(textColor.opacity(0.8))
                        }
                    }
                }

                Spacer(minLength: 0)

                Button {
                    let name = title.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !name.isEmpty else { return }
                    onSave(name, reminderDate)
                    dismiss()
                } label: {
                    Text("Save Task")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 18)
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [Color.white.opacity(0.35), Color.white.opacity(0.10)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .background(.ultraThinMaterial)
            )
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(.white.opacity(0.25), lineWidth: 1.2)
            )
            .shadow(color: .white.opacity(0.08), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 0)
            .padding(.bottom, 12)
        }
        .presentationDetents([.fraction(0.4), .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.clear)
        .alert("❗️Quick tip", isPresented: $showHelp) {
            Button("Got it") { }
        } message: {
            Text("""
                 Add your task and choose a reminder date and time.
                 Keep it clear and simple! 🙌
                 """)
        }
    }
}

// MARK: - الصفحة الرئيسية
struct ToDoListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var items: [ToDoItem] = [
        .init(title: "Buy water",     dueDate: .now, isDone: false),
        .init(title: "Read 10 pages", dueDate: .now.addingTimeInterval(86400), isDone: false),
        .init(title: "Gym session",   dueDate: .now, isDone: true)
    ]
    @State private var showAdd = false
    @State private var showHelp = false

    var textColor: Color = .black

    var body: some View {
        ZStack {
            Image("bg2")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer(minLength: 30)

                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.backward.circle.fill")
                            .font(.title2)
                            .foregroundColor(textColor)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text("To-Do List")
                        .font(.title2.bold())
                        .foregroundColor(textColor)
                    Spacer()
                    Button { showHelp = true } label: {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.yellow)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)

                List {
                    ForEach($items) { $item in
                        ToDoRow(item: $item, textColor: textColor)
                            .listRowBackground(Color.clear)
                    }
                    .onDelete { indexSet in
                        items.remove(atOffsets: indexSet)
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.plain)

                Button { showAdd = true } label: {
                    Label("Add New Task", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 18)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(.white.opacity(0.25), lineWidth: 1))
                }
                .padding(.bottom, 100)
            }
        }
        .sheet(isPresented: $showAdd) {
            AddTaskSheet(onSave: { title, date in
                items.append(.init(title: title, dueDate: date, isDone: false))
            }, textColor: textColor)
        }
        .alert("🍅 Welcome to Pomodoros To-Do!", isPresented: $showHelp) {
            Button("Got it") { }
        } message: {
            Text("""
                 • Track tasks, set reminders, and mark them done.
                 • Stay consistent — small progress adds up!
                 """)
        }
    }
}

#Preview {
    ToDoListView()
}
