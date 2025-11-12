import SwiftUI

/// 25m Work timer sheet: Start / Pause / Reset / Mark as Done
struct PomodoroWorkSheetView: View {
    let title: String
    let initialSeconds: Int
    var onResetClearDone: () -> Void
    var onMarkDone: () -> Void
    var onAutoComplete: () -> Void
    var onClose: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var remaining: Int
    @State private var running = false
    @State private var timer: Timer?

    init(title: String,
         initialSeconds: Int = 25 * 60,
         onResetClearDone: @escaping () -> Void,
         onMarkDone: @escaping () -> Void,
         onAutoComplete: @escaping () -> Void,
         onClose: @escaping () -> Void) {
        self.title = title
        self.initialSeconds = initialSeconds
        self.onResetClearDone = onResetClearDone
        self.onMarkDone = onMarkDone
        self.onAutoComplete = onAutoComplete
        self.onClose = onClose
        _remaining = State(initialValue: initialSeconds)
    }

    var body: some View {
        VStack(spacing: 20) {
            Capsule().fill(Color.secondary.opacity(0.4))
                .frame(width: 44, height: 5)
                .padding(.top, 8)

            Text(title).font(.headline)

            Text(timeString(remaining))
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .monospacedDigit()
                .onChange(of: remaining) { _, newVal in
                    if newVal == 0 {
                        stop()
                        onAutoComplete()
                    }
                }

            HStack(spacing: 12) {
                Button(action: toggle) {
                    Label(running ? "Pause" : "Start",
                          systemImage: running ? "pause.circle.fill" : "play.circle.fill")
                }.buttonStyle(.borderedProminent)

                Button(action: reset) {
                    Label("Reset", systemImage: "arrow.counterclockwise.circle")
                }.buttonStyle(.bordered)
            }

            Button {
                stop()
                onMarkDone()
            } label: {
                Label("Mark as Done", systemImage: "checkmark.seal.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)

            Spacer(minLength: 10)

            Button(role: .cancel) {
                stop()
                onClose()
                dismiss()
            } label: {
                Text("Close").foregroundColor(.secondary)
            }
            .padding(.bottom, 16)
        }
        .padding(20)
        .onDisappear { stop() }
    }

    // MARK: - Timer
    private func toggle() { running.toggle(); running ? start() : stop() }

    private func start() {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remaining > 0 { remaining -= 1 } else { stop() }
        }
        if let t = timer { RunLoop.current.add(t, forMode: .common) }
    }

    private func stop() { timer?.invalidate(); timer = nil; running = false }

    private func reset() {
        stop()
        onResetClearDone()
        remaining = initialSeconds
    }

    private func timeString(_ s: Int) -> String {
        let m = s / 60, r = s % 60
        return String(format: "%02d:%02d", m, r)
    }
}
