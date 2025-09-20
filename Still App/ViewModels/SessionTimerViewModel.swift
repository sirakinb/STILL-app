//
//  SessionTimerViewModel.swift
//  Still App
//
//  Created by Akinyemi Bajulaiye on 9/20/25.
//

import Foundation
import Combine

final class SessionTimerViewModel: ObservableObject {
    @Published private(set) var remainingSeconds: Int
    @Published private(set) var isRunning: Bool = false

    private var timer: AnyCancellable?
    private let totalSeconds: Int
    private let timerProvider: TimerProviding

    init(duration: TimeInterval, timerProvider: TimerProviding = DefaultTimerProvider()) {
        let seconds = Int(duration)
        self.totalSeconds = max(seconds, 0)
        self.remainingSeconds = max(seconds, 0)
        self.timerProvider = timerProvider
    }

    func start() {
        guard !isRunning, remainingSeconds > 0 else { return }
        isRunning = true
        timer = timerProvider.publisher(every: 1)
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    func endEarly() {
        remainingSeconds = 0
        finish()
    }

    func reset() {
        timer?.cancel()
        timer = nil
        remainingSeconds = totalSeconds
        isRunning = false
    }

    var totalDurationSeconds: Int {
        totalSeconds
    }

    var elapsedSeconds: Int {
        totalSeconds - remainingSeconds
    }

    private func tick() {
        guard remainingSeconds > 0 else {
            finish()
            return
        }

        remainingSeconds -= 1

        if remainingSeconds == 0 {
            finish()
        }
    }

    private func finish() {
        timer?.cancel()
        timer = nil
        isRunning = false
    }
}
