import SwiftUI
import Combine

// MARK: - Public notifications
extension Notification.Name {
    static let TUSessionCompleted25m = Notification.Name("TU.SessionCompleted25m")
    static let TUHarvestedTomatoAdded = Notification.Name("TU.HarvestedTomatoAdded")
    static let TUToDoItemsUpdated     = Notification.Name("TU.ToDoItemsUpdated")
}

// MARK: - Theme
enum TUHomeStyle {
    static let bgImage   = "bg2"

    static let topSpace: CGFloat   = 90
    static let padH: CGFloat       = 14
    static let padV: CGFloat       = 12

    static let corner: CGFloat     = 18
    static let bigCardH: CGFloat   = 180  // مساحة أكبر للحركة
    static let buttonH: CGFloat    = 64

    // أحجام مهمة
    static var centerImageSize: CGFloat   = 100
    static var harvestImageHeight: CGFloat = 110
}

// MARK: - Transparent card (glass style)
private struct HomeClearCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: TUHomeStyle.corner, style: .continuous)
                    .fill(Color.white.opacity(0.10).blendMode(.multiply))  // قزاز أشفّ
            )
            .overlay(
                RoundedRectangle(cornerRadius: TUHomeStyle.corner, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1.5)     // بوردر أنعم
            )
            .clipShape(RoundedRectangle(cornerRadius: TUHomeStyle.corner, style: .continuous))
    }
}
private extension View {
    func homeClearCard() -> some View { modifier(HomeClearCardModifier()) }
}

// MARK: - Streak (once per day when any 25m session completes)
@MainActor
final class TUStreakStore: ObservableObject {
    private let K_STREAK  = "TU.streak.current"
    private let K_LASTDAY = "TU.streak.lastDay" // yyyy-MM-dd

    @Published private(set) var current: Int = 0
    @Published private(set) var lastDayKey: String = ""

    private var cal: Calendar {
        var c = Calendar(identifier: .gregorian); c.firstWeekday = 1; return c
    }
    private var todayKey: String {
        let f = DateFormatter(); f.calendar = cal; f.dateFormat = "yyyy-MM-dd"
        return f.string(from: cal.startOfDay(for: Date()))
    }

    init() {
        current    = max(0, UserDefaults.standard.integer(forKey: K_STREAK))
        lastDayKey = UserDefaults.standard.string(forKey: K_LASTDAY) ?? ""

        if !lastDayKey.isEmpty {
            let f = DateFormatter(); f.calendar = cal; f.dateFormat = "yyyy-MM-dd"
            if let last = f.date(from: lastDayKey) {
                let yesterday = cal.date(byAdding: .day, value: -1, to: cal.startOfDay(for: Date()))!
                if !(cal.isDate(last, inSameDayAs: yesterday) || cal.isDate(last, inSameDayAs: Date())) {
                    current = 0; save()
                }
            }
        }

        NotificationCenter.default.addObserver(
            forName: .TUSessionCompleted25m, object: nil, queue: .main
        ) { [weak self] _ in self?.markToday() }
    }

    func markToday() {
        guard lastDayKey != todayKey else { return } // once per day
        var next = 1
        if !lastDayKey.isEmpty {
            let f = DateFormatter(); f.calendar = cal; f.dateFormat = "yyyy-MM-dd"
            if let last = f.date(from: lastDayKey) {
                let yesterday = cal.date(byAdding: .day, value: -1, to: cal.startOfDay(for: Date()))!
                if cal.isDate(last, inSameDayAs: yesterday) { next = current + 1 }
            }
        }
        current = next
        lastDayKey = todayKey
        save()
        objectWillChange.send()
    }

    private func save() {
        UserDefaults.standard.set(current, forKey: K_STREAK)
        UserDefaults.standard.set(lastDayKey, forKey: K_LASTDAY)
    }
}

// MARK: - Harvest (listens to TUHarvestedTomatoAdded)
@MainActor
final class TUHarvestStore: ObservableObject {
    private let K_COUNT = "TU.harvest.count"
    @Published private(set) var count: Int = 0

    init() {
        count = UserDefaults.standard.integer(forKey: K_COUNT)
        NotificationCenter.default.addObserver(
            forName: .TUHarvestedTomatoAdded, object: nil, queue: .main
        ) { [weak self] note in
            if let delta = note.userInfo?["delta"] as? Int { self?.increment(by: delta) }
            else { self?.increment(by: 1) }
        }
    }

    func increment(by n: Int) {
        count = max(0, count + n)
        UserDefaults.standard.set(count, forKey: K_COUNT)
        objectWillChange.send()
    }
}

// MARK: - ToDo feed (lightweight; reads from UserDefaults)
struct ToDoLite: Identifiable, Codable {
    let id: UUID
    var title: String
    var due: Date?
    init(id: UUID = UUID(), title: String, due: Date? = nil) {
        self.id = id; self.title = title; self.due = due
    }
}



@MainActor
final class TUToDoFeed: ObservableObject {
    private let K_ITEMS = "TU.todo.items"
    @Published var items: [ToDoLite] = []

    init() {
        load()

        // أي شاشة في التطبيق ترسل هذا النوتيفيكيشن → نعيد تحميل الليست
        NotificationCenter.default.addObserver(
            forName: .TUToDoItemsUpdated, object: nil, queue: .main
        ) { [weak self] _ in
            self?.load()
        }
    }

    // تحميل من UserDefaults
    func load() {
        if let data = UserDefaults.standard.data(forKey: K_ITEMS),
           let arr  = try? JSONDecoder().decode([ToDoLite].self, from: data) {
            items = arr
        } else {
            items = []
        }
        objectWillChange.send()
    }

    // حفظ في UserDefaults + إشعار باقي الشاشات
    func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: K_ITEMS)
        }
        objectWillChange.send()
        NotificationCenter.default.post(name: .TUToDoItemsUpdated, object: nil)
    }

    // إضافة مهمة جديدة (تستدعينها من شاشة الـ To-Do)
    func addItem(title: String, due: Date?) {
        let newItem = ToDoLite(title: title, due: due)
        items.append(newItem)
        save()
    }

    // حذف مهمات (مع onDelete في List)
    func deleteItems(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        save()
    }
}

// MARK: - Floating Tomatoes (wider play area)
struct FloatingTomatoesView: View {
    struct Sprite: Identifiable {
        let id = UUID()
        var x: CGFloat; var y: CGFloat
        var size: CGFloat
        var vx: CGFloat; var vy: CGFloat
        var imageName: String
    }

    var assetNames: [String] = ["Rtomato","YellowTomato","OrangeTomato","GreenTomato"]
    var count: Int = 48

    var centralImageName: String? = "SaturnTomato"
    var centralImageSize: CGFloat = TUHomeStyle.centerImageSize
    var centerBobAmplitude: CGFloat = 4
    var centerTiltDegrees: CGFloat = 3.0
    var centerBobDuration: Double = 2.0

    private let speedRange: ClosedRange<CGFloat> = 0.20...0.55
    private let margin: CGFloat = 16

    @State private var sprites: [Sprite] = []
    @State private var centerBob = false
    @State private var timer: Timer?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(sprites) { s in
                    Image(s.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: s.size, height: s.size)
                        .position(x: s.x, y: s.y)
                        .shadow(radius: 2, y: 1)
                }

                if let center = centralImageName {
                    Image(center)
                        .resizable()
                        .scaledToFit()
                        .frame(width: centralImageSize, height: centralImageSize)
                        .position(
                            x: geo.size.width / 2,
                            y: geo.size.height / 2 + (centerBob ? -centerBobAmplitude : centerBobAmplitude)
                        )
                        .rotationEffect(.degrees(centerBob ? centerTiltDegrees : -centerTiltDegrees))
                        .animation(.easeInOut(duration: centerBobDuration).repeatForever(autoreverses: true),
                                   value: centerBob)
                        .onAppear { centerBob = true }
                        .shadow(radius: 4, y: 2)
                }
            }
            .onAppear {
                spawnSprites(in: geo.size)
                startTick(in: geo.size)
            }
            .onDisappear { timer?.invalidate(); timer = nil }
        }
        .frame(height: TUHomeStyle.bigCardH)
        .padding(8)
        .homeClearCard()
    }

    private func spawnSprites(in size: CGSize) {
        let cols = Int(max(6, round(size.width / 60)))
        let rows = Int(max(3, round(size.height / 80)))
        var points: [CGPoint] = []

        for r in 0..<rows {
            for c in 0..<cols {
                let px = (CGFloat(c) + 0.5) * size.width  / CGFloat(cols)
                let py = (CGFloat(r) + 0.5) * size.height / CGFloat(rows)
                points.append(CGPoint(x: px, y: py))
            }
        }
        points.shuffle()

        let use = min(count, points.count)

        var cycle: [String] = []
        while cycle.count < use { cycle.append(contentsOf: assetNames) }
        cycle = Array(cycle.prefix(use)).shuffled()

        sprites = (0..<use).map { i in
            let p  = points[i]
            let jx = CGFloat.random(in: -12...12)
            let jy = CGFloat.random(in: -12...12)

            let speed = CGFloat.random(in: speedRange)
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let vx = speed * cos(angle)
            let vy = speed * sin(angle)

            return Sprite(
                x: min(max(margin, p.x + jx), size.width  - margin),
                y: min(max(margin, p.y + jy), size.height - margin),
                size: .random(in: 22...46),
                vx: vx, vy: vy,
                imageName: cycle[i]
            )
        }
    }

    private func startTick(in size: CGSize) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
            for i in sprites.indices {
                sprites[i].x += sprites[i].vx
                sprites[i].y += sprites[i].vy

                if sprites[i].x <= margin {
                    sprites[i].x = margin
                    sprites[i].vx = abs(sprites[i].vx)
                } else if sprites[i].x >= size.width - margin {
                    sprites[i].x = size.width - margin
                    sprites[i].vx = -abs(sprites[i].vx)
                }
                if sprites[i].y <= margin {
                    sprites[i].y = margin
                    sprites[i].vy = abs(sprites[i].vy)
                } else if sprites[i].y >= size.height - margin {
                    sprites[i].y = size.height - margin
                    sprites[i].vy = -abs(sprites[i].vy)
                }
            }
        }
    }
}

// MARK: - 25m Timer
@MainActor
final class HomeTimerVM: ObservableObject {
    @Published var remaining: Int = 25 * 60
    @Published var running: Bool = false
    private var timer: Timer?

    func toggle() { running ? pause() : start() }
    func start() {
        guard !running else { return }
        running = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self = self else { return }
            if self.remaining > 0 { self.remaining -= 1 }
            else {
                t.invalidate(); self.running = false; self.remaining = 0
                NotificationCenter.default.post(name: .TUSessionCompleted25m, object: nil)
            }
        }
    }
    func pause()  { running = false; timer?.invalidate(); timer = nil }
    func reset()  { pause(); remaining = 25 * 60 }
    var mmss: String { String(format: "%02d:%02d", remaining/60, remaining%60) }
}

struct TimerCard: View {
    @StateObject private var vm = HomeTimerVM()
    var body: some View {
        VStack(spacing: 14) {
            Text(vm.mmss)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(.white)

            HStack(spacing: 10) {
                Button { vm.toggle() } label: {
                    HStack(spacing: 8) {
                        Image(systemName: vm.running ? "pause.fill" : "play.fill")
                        Text(vm.running ? "Pause" : "Start 25m")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.10).blendMode(.multiply))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1.5)
                    )
                }

                Button("Reset") { vm.reset() }
                    .foregroundColor(.white.opacity(0.95))
                    .padding(.vertical, 12).padding(.horizontal, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.10).blendMode(.multiply))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1.5)
                    )            }
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .homeClearCard()
    }
}



// MARK: - Streak Card (نفس قزاز الكروت الثانية)
struct StreakCard: View {
    @ObservedObject var store: TUStreakStore

    var body: some View {
        VStack(spacing: 8) {
            Text("STREAK")
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.95))

            Image("Streak")               // 👈 من الـ Assets
                .resizable()
                .scaledToFit()
                .frame(height: 90)
                .shadow(radius: 2, y: 1)

            Text("\(store.current)")
                .font(.title3.bold())
                .foregroundColor(.white.opacity(0.96))
        }
        .frame(maxWidth: .infinity, minHeight: 130)
        .padding(10)
        .homeClearCard()                  // 👈 نفس القزاز حق الكارد اللي فوق
    }
}

// MARK: - Harvest Card (نفس القزاز بالضبط)
struct HarvestCard: View {
    @ObservedObject var store: TUHarvestStore

    var body: some View {
        VStack(spacing: 8) {
            Text("HARVESTED \n TOMATOES")
            
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.95))

            Image("tomato")               // 👈 من الـ Assets
                .resizable()
                .scaledToFit()
                .frame(height: 140)
                .padding(.bottom, -30)
                .padding(.top, -40)
                .shadow(radius: 2, y: 1)

            Text("\(store.count)")
                .font(.title3.bold())
                .foregroundColor(.white.opacity(0.96))
        }
        .frame(maxWidth: .infinity, minHeight: 130)
        .padding(10)
        .homeClearCard()                  // نفس Modifier الزجاجي
    }
}


// MARK: - Single To-Do Item card (inside Upcoming Events)
struct EventCardItem: View {
    var item: ToDoLite

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.title)
                .font(.headline)
                .foregroundColor(.white)

            if let d = item.due {
                Text(d.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }
}

// MARK: - Upcoming Events (smooth vertical slide between all todos)
struct UpcomingEventsCard: View {
    @ObservedObject var feed: TUToDoFeed

    @State private var currentIndex: Int = 0
    private let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    var body: some View {
        let items = feed.items

        VStack(alignment: .leading, spacing: 10) {
            Text("UPCOMING EVENTS")
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.95))

            if items.isEmpty {
                Text("No items yet.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
            } else {
                let safeIndex = min(currentIndex, items.count - 1)
                let item = items[safeIndex]

                EventCardItem(item: item)
                    .id(item.id)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.85),
                        value: currentIndex
                    )
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading) // نفس ارتفاع المربعات الأخرى
        .padding(EdgeInsets(top: 0, leading: 0, bottom: -30, trailing: 0))   
        .homeClearCard()
        .onReceive(timer) { _ in
            guard !feed.items.isEmpty else { return }
            let count = feed.items.count
            withAnimation {
                currentIndex = (currentIndex + 1) % count
            }
        }
        .onReceive(feed.$items) { newItems in
            if newItems.isEmpty {
                currentIndex = 0
            } else if currentIndex >= newItems.count {
                currentIndex = max(0, newItems.count - 1)
            }
        }
    }
}

// MARK: - Home View
struct TUHomeView: View {
    @StateObject private var streakStore  = TUStreakStore()
    @StateObject private var harvestStore = TUHarvestStore()
    @StateObject private var todoFeed     = TUToDoFeed()

    var body: some View {
        NavigationStack {
            ZStack {
                Image(TUHomeStyle.bgImage)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        Spacer().frame(height: TUHomeStyle.topSpace)

                        FloatingTomatoesView(
                            assetNames: ["Rtomato","YellowTomato","OrangeTomato","GreenTomato"],
                            count: 48,
                            centralImageName: "SaturnTomato",
                            centralImageSize: TUHomeStyle.centerImageSize,
                            centerBobAmplitude: 4,
                            centerTiltDegrees: 3.0,
                            centerBobDuration: 2.0
                        )
                        .padding(.horizontal, TUHomeStyle.padH)

                        TimerCard()
                            .padding(.horizontal, TUHomeStyle.padH)

                        HStack(spacing: 20) {
                            StreakCard(store: streakStore)
                            HarvestCard(store: harvestStore)
                        }
                        .padding(.horizontal, TUHomeStyle.padH)

                        UpcomingEventsCard(feed: todoFeed)
                            .padding(.horizontal, TUHomeStyle.padH)

                        Spacer(minLength: 28)
                    }
                    .padding(.vertical, TUHomeStyle.padV)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.clear, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

// MARK: - Preview
#Preview {
    TUHomeView()
        .environment(\.locale, .init(identifier: "en_US"))
}
