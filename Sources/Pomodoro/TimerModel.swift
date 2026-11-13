import AppKit
import Foundation

enum Phase: String {
    case work, shortBreak, longBreak

    var title: String {
        switch self {
        case .work: return "Focus"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }

    var icon: String { self == .work ? "🍅" : "☕" }
}

enum RunState { case idle, running, paused }

@MainActor
final class TimerModel: ObservableObject {
    private let defaults = UserDefaults.standard

    @Published var workMinutes: Int { didSet { defaults.set(workMinutes, forKey: "workMinutes"); durationChanged(.work) } }
    @Published var shortBreakMinutes: Int { didSet { defaults.set(shortBreakMinutes, forKey: "shortBreakMinutes"); durationChanged(.shortBreak) } }
    @Published var longBreakMinutes: Int { didSet { defaults.set(longBreakMinutes, forKey: "longBreakMinutes"); durationChanged(.longBreak) } }
    @Published var sessionsBeforeLongBreak: Int { didSet { defaults.set(sessionsBeforeLongBreak, forKey: "sessionsBeforeLongBreak") } }

    @Published private(set) var phase: Phase = .work
    @Published private(set) var state: RunState = .idle
    @Published private(set) var remaining: TimeInterval = 0
    @Published private(set) var completedSessions = 0

    private var endDate: Date?
    private var timer: Timer?

    init() {
        func load(_ key: String, _ fallback: Int) -> Int {
            let v = UserDefaults.standard.integer(forKey: key)
            return v > 0 ? v : fallback
        }
        workMinutes = load("workMinutes", 25)
        shortBreakMinutes = load("shortBreakMinutes", 5)
        longBreakMinutes = load("longBreakMinutes", 15)
        sessionsBeforeLongBreak = load("sessionsBeforeLongBreak", 4)
        remaining = duration(for: .work)
    }

    func duration(for phase: Phase) -> TimeInterval {
        switch phase {
        case .work: return TimeInterval(workMinutes * 60)
        case .shortBreak: return TimeInterval(shortBreakMinutes * 60)
        case .longBreak: return TimeInterval(longBreakMinutes * 60)
        }
    }

    var timeString: String {
        let total = Int(remaining.rounded(.up))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    var menuBarTitle: String {
        state == .idle ? phase.icon : "\(phase.icon) \(timeString)"
    }

    // MARK: Controls

    func toggle() {
        switch state {
        case .running: pause()
        case .idle, .paused: start()
        }
    }

    func start() {
        endDate = Date().addingTimeInterval(remaining)
        state = .running
        let t = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer?.invalidate()
        timer = t
    }

    func pause() {
        tick()
        stopTimer()
        state = .paused
    }

    func reset() {
        stopTimer()
        state = .idle
        remaining = duration(for: phase)
    }

    func skip() {
        advance(countSession: false)
    }

    func resetAll() {
        completedSessions = 0
        phase = .work
        reset()
    }

    // MARK: Internals

    private func tick() {
        guard let endDate else { return }
        remaining = max(0, endDate.timeIntervalSinceNow)
        if remaining <= 0 {
            NSSound(named: "Glass")?.play()
            advance(countSession: true)
        }
    }

    private func advance(countSession: Bool) {
        stopTimer()
        if phase == .work {
            if countSession { completedSessions += 1 }
            let n = max(1, sessionsBeforeLongBreak)
            phase = (countSession && completedSessions % n == 0) ? .longBreak : .shortBreak
        } else {
            phase = .work
        }
        state = .idle
        remaining = duration(for: phase)
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        endDate = nil
    }

    private func durationChanged(_ p: Phase) {
        if p == phase && state == .idle { remaining = duration(for: p) }
    }
}
