import SwiftUI

struct PomodorosView: View {
    @EnvironmentObject var vm: PomodoroViewModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(vm.parentTasks) { task in
                    NavigationLink {
                        PomodoroChildView(parent: task)
                            .environmentObject(vm)
                    } label: {
                        HStack(spacing: 12) {
                            // ✅ نفس أيقونة البندورة الأصلية (مكبّرة 40% بحسب UIK)
                            Image(UIK.icon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: UIK.parentIconSize * UIK.tomatoScale,
                                       height: UIK.parentIconSize * UIK.tomatoScale)
                                .opacity(0.95)

                            // ✅ العنوان فقط
                            Text(task.title)
                                .font(.headline)

                            Spacer()
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .topSafeInset() // من نقاطك: إصلاح الجزء العلوي
        }
        .navigationTitle("Pomodoros")
        .navigationBarTitleDisplayMode(.inline)
        .whiteNavBar() // من نقاطك: شريط أبيض
        .background(Image(UIK.bg).resizable().scaledToFill().ignoresSafeArea())
    }
}
