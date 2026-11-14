import SwiftUI

struct MenuView: View {
    @ObservedObject var model: TimerModel

    var body: some View {
        VStack(spacing: 12) {
            Text(model.phase.title)
                .font(.headline)
            Text(model.timeString)
                .font(.system(size: 44, weight: .medium, design: .rounded))
                .monospacedDigit()
            Text("Sessions completed: \(model.completedSessions)")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Button(model.state == .running ? "Pause" : "Start") { model.toggle() }
                    .keyboardShortcut(.defaultAction)
                Button("Reset") { model.reset() }
                Button("Skip") { model.skip() }
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Stepper("Focus: \(model.workMinutes) min", value: $model.workMinutes, in: 1...90)
                Stepper("Short break: \(model.shortBreakMinutes) min", value: $model.shortBreakMinutes, in: 1...30)
                Stepper("Long break: \(model.longBreakMinutes) min", value: $model.longBreakMinutes, in: 1...60)
                Stepper("Long break every \(model.sessionsBeforeLongBreak) sessions", value: $model.sessionsBeforeLongBreak, in: 2...8)
            }

            Divider()

            Toggle("Start at Login", isOn: $model.startAtLogin)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Button("Reset All") { model.resetAll() }
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
            }
        }
        .padding()
        .frame(width: 280)
    }
}
