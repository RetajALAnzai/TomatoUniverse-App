import SwiftUI

struct ContentView: View {
    @StateObject private var vm = PomodoroViewModel()

    var body: some View {
        TabView {
            // Pomodoros
            NavigationStack {
                Pomodoros()
                    .navigationTitle("Pomodoros")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem { Label("Pomodoros", systemImage: "timer") }

            // Home
            NavigationStack {
                TUHomeView()
                    .navigationTitle("The Universe")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem { Label("Home", systemImage: "house.fill") }

            // To-Do
            NavigationStack {
                ToDoListView()
                    .navigationTitle("To-Do List")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem { Label("To Do", systemImage: "checklist") }
        }
        .environmentObject(vm)
        .accentColor(.white)
    }
}

#if DEBUG
#Preview("ContentView") {
    ContentView()
        .environmentObject(PreviewMocks.vm)
}
#endif
