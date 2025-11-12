import SwiftUI

/// 5-minute Break sheet: Start/Pause/Reset + Photo Library / Camera + Next 25
struct PomodoroBreakSheetView: View {
    let title: String
    let initialSeconds: Int
    var onPickFromLibrary: () -> Void
    var onOpenCamera: () -> Void
    var onNext25: () -> Void
    var onClose: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var remaining: Int
    @State private var running = false
    @State private var timer: Timer?

    init(title: String = "٥ دقائق بريك",
         initialSeconds: Int = 5 * 60,
         onPickFromLibrary: @escaping () -> Void,
         onOpenCamera: @escaping () -> Void,
         onNext25: @escaping () -> Void,
         onClose: @escaping () -> Void) {
        self.title = title
        self.initialSeconds = initialSeconds
        self.onPickFromLibrary = onPickFromLibrary
        self.onOpenCamera = onOpenCamera
        self.onNext25 = onNext25
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
                .font(.system(size: 36, weight: .semibold, design: .rounded))
                .monospacedDigit()

            HStack(spacing: 12) {
                Button(action: toggle) {
                    Label(running ? "Pause" : "Start",
                          systemImage: running ? "pause.circle.fill" : "play.circle.fill")
                }
                .buttonStyle(.borderedProminent)

                Button(action: reset) {
                    Label("Reset", systemImage: "arrow.counterclockwise.circle")
                }
                .buttonStyle(.bordered)
            }

            HStack(spacing: 12) {
                Button(action: onPickFromLibrary) {
                    Label("Photo Library", systemImage: "photo.on.rectangle")
                }
                .buttonStyle(.bordered)

                Button(action: onOpenCamera) {
                    Label("Camera", systemImage: "camera")
                }
                .buttonStyle(.bordered)
            }

            Button(action: onNext25) {
                Label("Next 25 minutes", systemImage: "arrow.right.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)

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

    private func reset() { stop(); remaining = initialSeconds }

    private func timeString(_ s: Int) -> String {
        let m = s / 60, r = s % 60
        return String(format: "%02d:%02d", m, r)
    }
}
