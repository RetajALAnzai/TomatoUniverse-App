import SwiftUI

@main
struct TomatoUniverseApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

#if DEBUG
#Preview("App Entry") {
    ContentView()
        .environmentObject(PreviewMocks.vm)
}
#endif
