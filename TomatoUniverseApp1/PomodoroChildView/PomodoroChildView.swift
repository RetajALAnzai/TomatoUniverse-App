import SwiftUI
import PhotosUI

private enum TUChildStyle {
    static let topInset: CGFloat = 0      // للمسافة الخاصة بالـ safe area inset
    static let gridTopSpace: CGFloat = 40  // ← المسافة بين التولبار وأول صف من المربعات (عدّلها)
}

struct PomodoroChildView: View {
    @Binding var set: PomodoroSet
    let totalCount: Int

    @State private var showTimer = false
    @State private var showPhotos = false
    @State private var showInfo = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)

    var body: some View {
        NavigationStack {
            ZStack {
                Image(UIK.bg).resizable().scaledToFill().ignoresSafeArea()

                VStack(spacing: 14) {
                    Text(set.title)
                        .font(.title3.bold())
                        .foregroundColor(.white)
                        .padding(.top, 10)

                    ScrollView {
                        // ✅ المسافة الإضافية بين التولبار والشبكة
                        Spacer().frame(height: TUChildStyle.gridTopSpace)

                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(set.items) { item in
                                cell(for: item)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.bottom, 20)
                    }

                    HStack(spacing: 12) {
                        Button {
                            showTimer = true
                        } label: {
                            Label("Start Focus", systemImage: "timer")
                                .padding(.horizontal, 16).padding(.vertical, 10)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                                .foregroundColor(.white)
                        }

                        Button {
                            showPhotos = true
                        } label: {
                            Label("Manage Photos", systemImage: "photo.on.rectangle.angled")
                                .padding(.horizontal, 16).padding(.vertical, 10)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.bottom, 10)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.clear, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showInfo = true } label: {
                        Image(systemName: "exclamationmark.circle")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(.trailing, 0)
                    }
                }
            }
            .sheet(isPresented: $showInfo) {
                InfoSheetView()
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showTimer) {
                PomodoroTimerView(title: set.title)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showPhotos) {
                PhotoManagerSheet()
                    .presentationDetents([.medium, .large])
            }
        }
        // يمنع المربعات من الالتصاق بالتولبار عند عدم وجود سكرول
        .safeAreaInset(edge: .top) {
            Color.clear.frame(height: TUChildStyle.topInset)
        }
    }

    // MARK: - خلية المربع
    @ViewBuilder
    private func cell(for item: TomatoItem) -> some View {
        let isCurrent = (item.id == set.currentIndex)
        let bg: Color = {
            switch item.state {
            case .locked:    return .white.opacity(0.10)
            case .available: return isCurrent ? .white.opacity(0.28) : .white.opacity(0.18)
            case .done:      return .green.opacity(0.35)
            }
        }()

        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(bg)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.white.opacity(0.18), lineWidth: 1)
                )

            Image("tomato")
                .resizable()
                .scaledToFit()
                .frame(height: UIK.childCellHeight * 1)
                .colorMultiply(tomatoColor(for: item.id))
                .shadow(radius: 2, y: 1)

            Text("\(item.id)")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.top, 4)
                .padding(.leading, 6)
        }
        .frame(height: UIK.childCellHeight)
        .frame(maxWidth: .infinity)
        .clipped()
        .contentShape(Rectangle())
        .onTapGesture { handleTap(item.id) }
    }

    private func tomatoColor(for index: Int) -> Color {
        let t = Double(index - 1) / Double(max(totalCount - 1, 1))
        let hue = 0.33 * (1.0 - t)
        let saturation = 0.95
        let brightness = 0.70 + 0.25 * t
        return Color(hue: hue, saturation: saturation, brightness: brightness)
    }

    private func handleTap(_ id: Int) {
        guard id == set.currentIndex else { return }
        if let idx = set.items.firstIndex(where: { $0.id == id }) {
            set.items[idx].state = .done
        }
        let next = id + 1
        if let nextIdx = set.items.firstIndex(where: { $0.id == next }) {
            set.items[nextIdx].state = .available
            set.currentIndex = next
        }
    }
}

// MARK: - شاشة الشرح
private struct InfoSheetView: View {
    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 48, height: 5)
                .padding(.top, 8)

            Text("About this Set")
                .font(.title3.bold())
                .padding(.top, 4)

            // ✏️ غيّر النص هنا
            Text("اكتب هنا شرح المجموعة: الهدف منها، طريقة الاستخدام، وأي ملاحظات مهمة.")
                .multilineTextAlignment(.center)
                .padding()
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(20)
    }
}

// MARK: - شيت الصور المؤقت
private struct PhotoManagerSheet: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled").font(.largeTitle)
            Text("Photos coming soon")
            Text("Temporary sheet to keep the build green.")
                .font(.footnote).foregroundColor(.secondary)
        }
        .padding()
    }
}

#if DEBUG
#Preview("PomodoroChildView") {
    let set = PreviewMocks.vm.sets.first ?? .make(title: "Sample", total: 50)
    return PomodoroChildView(set: .constant(set), totalCount: set.items.count)
}
#endif
