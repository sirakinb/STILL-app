//
//  SessionHistoryStore.swift
//  Still App
//
//  Maintains a lightweight, on-device log of recent meditation sessions
//  and derives simple stats like streaks and total minutes.
//

import Foundation

struct MeditationLog: Identifiable, Codable, Hashable {
    let id: UUID
    let startedAt: Date
    let sessionTitle: String
    let scheduledDurationSeconds: Int
    let actualDurationSeconds: Int
    let completedNaturally: Bool
    let endedEarly: Bool
    private let soundscapeRawValue: String?

    init(
        id: UUID = UUID(),
        startedAt: Date,
        sessionTitle: String,
        scheduledDurationSeconds: Int,
        actualDurationSeconds: Int,
        completedNaturally: Bool,
        endedEarly: Bool,
        soundscape: SoundscapeOption?
    ) {
        self.id = id
        self.startedAt = startedAt
        self.sessionTitle = sessionTitle
        self.scheduledDurationSeconds = scheduledDurationSeconds
        self.actualDurationSeconds = actualDurationSeconds
        self.completedNaturally = completedNaturally
        self.endedEarly = endedEarly
        self.soundscapeRawValue = soundscape?.rawValue
    }

    var soundscape: SoundscapeOption? {
        guard let raw = soundscapeRawValue else { return nil }
        return SoundscapeOption(rawValue: raw)
    }

    var actualMinutes: Int {
        max(1, Int(round(Double(actualDurationSeconds) / 60.0)))
    }
}

@MainActor
final class SessionHistoryStore: ObservableObject {
    @Published private(set) var sessions: [MeditationLog]
    @Published private(set) var currentStreak: Int = 0
    @Published private(set) var totalMinutes: Int = 0

    private let storage: SettingsStoring
    private let historyKey = "history.sessions"
    private let maxStoredSessions = 14

    init(storage: SettingsStoring = UserDefaults.standard) {
        self.storage = storage
        if let data = storage.object(forKey: historyKey) as? Data {
            let decoded = try? JSONDecoder().decode([MeditationLog].self, from: data)
            self.sessions = decoded ?? []
        } else {
            self.sessions = []
        }
        recalcStats()
    }

    func record(
        session: MeditationSession,
        startedAt: Date,
        actualDurationSeconds: Int,
        completedNaturally: Bool,
        endedEarly: Bool,
        soundscape: SoundscapeOption?
    ) {
        let sanitizedDuration = max(0, actualDurationSeconds)
        let log = MeditationLog(
            startedAt: startedAt,
            sessionTitle: session.title,
            scheduledDurationSeconds: Int(session.duration),
            actualDurationSeconds: sanitizedDuration,
            completedNaturally: completedNaturally,
            endedEarly: endedEarly,
            soundscape: soundscape
        )

        sessions.insert(log, at: 0)
        if sessions.count > maxStoredSessions {
            sessions = Array(sessions.prefix(maxStoredSessions))
        }

        persist()
        recalcStats()
    }

    var recentSessions: [MeditationLog] {
        Array(sessions.prefix(5))
    }

    var lastCompletedSession: MeditationLog? {
        sessions.first(where: { $0.completedNaturally && !$0.endedEarly })
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        if let data = try? encoder.encode(sessions) {
            storage.set(data, forKey: historyKey)
        }
    }

    private func recalcStats() {
        totalMinutes = sessions.reduce(0) { partial, log in
            partial + max(1, Int(round(Double(log.actualDurationSeconds) / 60.0)))
        }

        currentStreak = computeStreak()
    }

    private func computeStreak() -> Int {
        let calendar = Calendar.current
        let completedDays = Set(
            sessions
                .filter { $0.completedNaturally && !$0.endedEarly }
                .map { calendar.startOfDay(for: $0.startedAt) }
        )

        guard !completedDays.isEmpty else { return 0 }

        var streak = 0
        var day = calendar.startOfDay(for: Date())

        while completedDays.contains(day) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previousDay
        }

        return streak
    }
}
