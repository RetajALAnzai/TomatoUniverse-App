import Foundation

public enum TomatoState: String, Codable { case locked, available, done }

public struct TomatoItem: Identifiable, Codable {
    public let id: Int
    public var state: TomatoState
    public var photoData: Data?
    public init(id: Int, state: TomatoState, photoData: Data? = nil) {
        self.id = id; self.state = state; self.photoData = photoData
    }
}

public struct PomodoroSet: Identifiable, Codable {
    public var id: UUID = .init()
    public var title: String
    public var targetNote: String?
    public var targetDate: Date?
    public var items: [TomatoItem]
    public var currentIndex: Int
    public var harvestCount: Int
    public var canHarvest: Bool

    public init(id: UUID = .init(),
                title: String,
                targetNote: String? = nil,
                targetDate: Date? = nil,
                items: [TomatoItem],
                currentIndex: Int = 1,
                harvestCount: Int = 0,
                canHarvest: Bool = false) {
        self.id = id
        self.title = title
        self.targetNote = targetNote
        self.targetDate = targetDate
        self.items = items
        self.currentIndex = currentIndex
        self.harvestCount = harvestCount
        self.canHarvest = canHarvest
    }

    public static func make(title: String,
                            targetNote: String? = nil,
                            targetDate: Date? = nil,
                            total: Int = 50) -> PomodoroSet {
        let t = max(1, total)
        let items = (1...t).map { TomatoItem(id: $0, state: $0 == 1 ? .available : .locked) }
        return PomodoroSet(title: title,
                           targetNote: targetNote,
                           targetDate: targetDate,
                           items: items,
                           currentIndex: 1,
                           harvestCount: 0,
                           canHarvest: false)
    }

    public var doneCount: Int { items.filter { $0.state == .done }.count }
}
