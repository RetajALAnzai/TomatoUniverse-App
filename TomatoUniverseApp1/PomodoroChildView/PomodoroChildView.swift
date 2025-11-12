import SwiftUI
import PhotosUI
import UIKit

// MARK: - Child layout constants (baseline-safe)
private enum TUChildStyle {
    static let topInset: CGFloat = 0
    static let gridTopSpace: CGFloat = 40
}

// MARK: - Formatters
private let childDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateStyle = .medium
    f.timeStyle = .none
    return f
}()

struct PomodoroChildView: View {
    @Binding var set: PomodoroSet
    let totalCount: Int

    // State
    @State private var selectedIndex: Int? = nil
    @State private var showWorkSheet = false
    @State private var showBreakSheet = false
    @State private var showInfo = false
    @State private var showPhotoManager = false

    // Order-enforcement alert
    @State private var showOrderAlert = false
    @State private var allowedIndexHint: Int = 0

    // Photos (work/break & manager)
    @State private var showLibrary = false
    @State private var librarySelection: PhotosPickerItem? = nil
    @State private var showCamera = false

    // MARK: - Harvest (new)
    @State private var showHarvestBanner = false     // إظهار بانر Collect
    @State private var harvestedThisSession = false  // حماية إضافية داخل الجلسة فقط

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)

    // First tomato that is not done yet (0-based)
    private var firstPendingIdx: Int {
        self.set.items.firstIndex(where: { $0.state != .done }) ?? (self.set.items.count - 1)
    }

    // MARK: - Harvest Persistence Key
    private var harvestClaimKey: String {
        // يخزن حالة الحصاد لهذا القسم فقط (يعتمد على set.id)
        "TU.harvest.claimed.\(set.id.uuidString)"
    }

    private func isHarvestClaimed() -> Bool {
        UserDefaults.standard.bool(forKey: harvestClaimKey)
    }

    private func markHarvestClaimed() {
        UserDefaults.standard.set(true, forKey: harvestClaimKey)
    }

    private func allTomatoesDone() -> Bool {
        set.items.filter { $0.state == .done }.count >= totalCount
    }

    private func checkAndShowHarvest() {
        // يظهر البانر فقط إذا اكتملت الـ50 ولم تُحصَد مسبقًا
        if allTomatoesDone() && !isHarvestClaimed() && !harvestedThisSession {
            withAnimation { showHarvestBanner = true }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Image(UIK.bg)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                VStack(spacing: 5) {
                    Text(set.title)
                        .font(.title3.bold())
                        .foregroundColor(.white)
                        .padding(.top, 10)

                    // Centered Target date + Goal (vertical style)
                    if set.targetDate != nil || (set.targetNote != nil && !(set.targetNote ?? "").isEmpty) {
                        HStack(spacing: 30) {
                            if let d = set.targetDate {
                                VStack(spacing: 4) {
                                    Image(systemName: "calendar.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.white.opacity(0.9))
                                    Text(childDateFormatter.string(from: d))
                                        .font(.footnote)
                                        .foregroundColor(.white.opacity(0.9))
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.8)
                                }
                                .frame(maxWidth: .infinity)
                            }

                            if let note = set.targetNote, !note.isEmpty {
                                VStack(spacing: 4) {
                                    Image(systemName: "target")
                                        .font(.title3)
                                        .foregroundStyle(.white.opacity(0.9))
                                    Text(note)
                                        .font(.footnote)
                                        .foregroundColor(.white.opacity(0.9))
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.8)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                    }

                    ScrollView {
                        Spacer().frame(height: TUChildStyle.gridTopSpace)

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(set.items.indices, id: \.self) { idx in
                                cell(for: set.items[idx])
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if set.items[idx].state == .done {
                                            // فتح مدير الصور للمربعات المكتملة
                                            selectedIndex = idx
                                            showPhotoManager = true
                                        } else if idx == firstPendingIdx {
                                            // فتح ورقة عمل 25 دقيقة للمربع المسموح
                                            selectedIndex = idx
                                            showWorkSheet = true
                                        } else {
                                            // تنبيه الالتزام بالترتيب
                                            allowedIndexHint = (firstPendingIdx < set.items.count)
                                                ? set.items[firstPendingIdx].id
                                                : set.items.last?.id ?? 1
                                            showOrderAlert = true
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 30)
                    }
                }
                .padding(.top, TUChildStyle.topInset)

                // MARK: - Harvest Banner (new)
                if showHarvestBanner {
                    VStack {
                        Spacer()
                        HStack(spacing: 12) {
                            Image(systemName: "leaf.fill")
                                .imageScale(.large)

                            Text("Harvest a Tomato")
                                .font(.headline)

                            Spacer()

                            Button {
                                // منع الدبل كاونت
                                harvestedThisSession = true
                                markHarvestClaimed()

                                // إشعار للهوم لزيادة العداد
                                NotificationCenter.default.post(name: .TUHarvestedTomatoAdded, object: nil)

                                withAnimation { showHarvestBanner = false }

                                #if os(iOS)
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                #endif
                            } label: {
                                Text("Collect")
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(14)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.25), lineWidth: 1))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .shadow(radius: 10, y: 6)
                    }
                    .ignoresSafeArea(edges: .bottom)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)

            // Toolbar
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showInfo = true } label: {
                        Image(systemName: "exclamationmark.circle")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            .sheet(isPresented: $showInfo) {
                VStack(spacing: 20) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.4))
                        .frame(width: 44, height: 5)
                        .padding(.top, 8)

                    Text("Quick guide:\n\nTap the allowed square to start a 25-minute Pomodoro. After finishing, you’ll get a 5-minute break sheet with photo options. You must progress in order; you can’t open later squares before completing the current one.")
                        .multilineTextAlignment(.center)
                        .padding()

                    Spacer(minLength: 10)

                    Button("Close") { showInfo = false }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .padding(.bottom, 20)
                }
                .padding(20)
                .presentationDetents([.fraction(0.4), .medium])
            }

            // Alert for order enforcement
            .alert("Complete in order", isPresented: $showOrderAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("You can only open Tomato #\(allowedIndexHint) now. Finish it first to proceed.")
            }

            // 25-minute work sheet
            .sheet(isPresented: $showWorkSheet) {
                if let idx = selectedIndex {
                    PomodoroWorkSheetView(
                        title: "Tomato #\(set.items[idx].id)",
                        initialSeconds: 25 * 60,
                        onResetClearDone: {
                            if set.items[idx].state == .done { set.items[idx].state = .available }
                        },
                        onMarkDone: {
                            withAnimation(.spring) { set.items[idx].state = .done }
                            // تحقق من الحصاد
                            checkAndShowHarvest()

                            showWorkSheet = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { showBreakSheet = true }
                        },
                        onAutoComplete: {
                            withAnimation(.spring) { set.items[idx].state = .done }
                            // تحقق من الحصاد
                            checkAndShowHarvest()

                            showWorkSheet = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { showBreakSheet = true }
                        },
                        onClose: { showWorkSheet = false }
                    )
                }
            }

            // 5-minute break sheet
            .sheet(isPresented: $showBreakSheet) {
                if let idx = selectedIndex {
                    PomodoroBreakSheetView(
                        title: "5-minute break",
                        initialSeconds: 5 * 60,
                        onPickFromLibrary: { showLibrary = true },
                        onOpenCamera: { showCamera = true },
                        onNext25: {
                            showBreakSheet = false
                            let next = min(idx + 1, set.items.count - 1)
                            selectedIndex = next
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { showWorkSheet = true }
                        },
                        onClose: { showBreakSheet = false }
                    )
                    .photosPicker(isPresented: $showLibrary, selection: $librarySelection, matching: .images)
                    .onChange(of: librarySelection) { _, _ in
                        Task { await loadPickedPhotoToCurrentItem() }
                    }
                    .sheet(isPresented: $showCamera) {
                        CameraPickerView { img in
                            if let data = img?.jpegData(compressionQuality: 0.9),
                               let sIdx = selectedIndex {
                                set.items[sIdx].photoData = data
                            }
                            showCamera = false
                        }
                    }
                }
            }

            // Photo manager for completed squares
            .sheet(isPresented: $showPhotoManager) {
                if let idx = selectedIndex {
                    PhotoManageSheetView(
                        imageData: set.items[idx].photoData,
                        title: "Tomato #\(set.items[idx].id)",
                        onPickFromLibrary: { showLibrary = true },
                        onOpenCamera: { showCamera = true },
                        onDelete: {
                            set.items[idx].photoData = nil
                        },
                        onRestart25: {
                            set.items[idx].state = .available
                            showPhotoManager = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                showWorkSheet = true
                            }
                        },
                        onClose: { showPhotoManager = false }
                    )
                    .photosPicker(isPresented: $showLibrary, selection: $librarySelection, matching: .images)
                    .onChange(of: librarySelection) { _, _ in
                        Task { await loadPickedPhotoToCurrentItem() }
                    }
                    .sheet(isPresented: $showCamera) {
                        CameraPickerView { img in
                            if let data = img?.jpegData(compressionQuality: 0.9),
                               let sIdx = selectedIndex {
                                set.items[sIdx].photoData = data
                            }
                            showCamera = false
                        }
                    }
                    .presentationDetents([.medium, .large])
                }
            }
        }
        .onAppear {
            // لو كل الـ50 منتهية مسبقًا وما تحصدت، يظهر البانر
            checkAndShowHarvest()
        }
    }

    // MARK: - Cell
    @ViewBuilder
    private func cell(for item: TomatoItem) -> some View {
        let corner: CGFloat = 18

        ZStack {
            GeometryReader { geo in
                let w = geo.size.width
                if let img = uiImage(from: item.photoData) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: w, height: UIK.childCellHeight)
                        .clipped()
                } else {
                    Color.clear
                        .frame(width: w, height: UIK.childCellHeight)
                }
            }
            .frame(height: UIK.childCellHeight)
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))

            Image(UIK.icon)
                .resizable()
                .scaledToFit()
                .frame(height: UIK.childCellHeight)
                .colorMultiply(tomatoColor(for: item.id))
                .shadow(radius: 2, y: 1)
                .opacity(item.state == .locked ? 0.35 : 1.0)

            Text("\(item.id)")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.top, 4)
                .padding(.leading, 6)
        }
        .frame(height: UIK.childCellHeight)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(Color.white.opacity(0.12).blendMode(.multiply))
        )
        .overlay(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
        .clipped()
        .overlay(alignment: .topTrailing) {
            if item.state == .done {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.green)
                    .shadow(radius: 2)
                    .padding(6)
            }
        }
    }

    // MARK: - Color
    private func tomatoColor(for index: Int) -> Color {
        let t = Double(index - 1) / Double(max(totalCount - 1, 1))
        let hue = 0.38 * (1.0 - t)
        let saturation = 0.95
        let brightness = 0.95 + 0.10 * t
        return Color(hue: hue, saturation: saturation, brightness: brightness)
    }

    // MARK: - Photo utils
    private func loadPickedPhotoToCurrentItem() async {
        guard let item = librarySelection else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let idx = selectedIndex {
                set.items[idx].photoData = data
            }
        } catch { }
        librarySelection = nil
    }

    private func uiImage(from data: Data?) -> UIImage? {
        guard let data else { return nil }
        return UIImage(data: data)
    }
}

// MARK: - Photo Manager Sheet
private struct PhotoManageSheetView: View {
    let imageData: Data?
    let title: String
    let onPickFromLibrary: () -> Void
    let onOpenCamera: () -> Void
    let onDelete: () -> Void
    let onRestart25: () -> Void
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if let data = imageData, let ui = UIImage(data: data) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(.white.opacity(0.15), lineWidth: 1)
                        )
                        .padding(.horizontal)
                } else {
                    Text("No photo yet")
                        .foregroundColor(.secondary)
                        .padding(.top, 40)
                }

                VStack(spacing: 10) {
                    Button("Change from Library") { onPickFromLibrary() }
                        .buttonStyle(.borderedProminent)
                    Button("Take a Photo") { onOpenCamera() }
                        .buttonStyle(.bordered)
                    Button("Delete Photo") { onDelete() }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    Button("Restart 25 minutes") { onRestart25() }
                        .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)
                Spacer(minLength: 10)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { onClose() }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("PomodoroChildView") {
    let items = (1...50).map { TomatoItem(id: $0, state: .available) }
    let demoSet = PomodoroSet(id: UUID(), title: "Pomodoro Set", items: items, currentIndex: 1)
    PomodoroChildView(set: .constant(demoSet), totalCount: 50)
}
