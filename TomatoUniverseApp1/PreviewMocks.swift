#if DEBUG
import SwiftUI

enum PreviewMocks {
    static let vm: PomodoroViewModel = {
        let vm = PomodoroViewModel()
        // نكتب فوق المحفوظات لأجل المعاينة فقط
        vm.sets = [
            .make(title: "Spanish", targetNote: "Daily conversation", targetDate: .now.addingTimeInterval(TimeInterval(3*86400))),
            .make(title: "Reading", targetNote: "Finish 200 pages", targetDate: .now.addingTimeInterval(TimeInterval(10*86400)))
        ]
        return vm
    }()
}
#endif
