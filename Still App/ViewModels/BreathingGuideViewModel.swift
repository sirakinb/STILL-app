//
//  BreathingGuideViewModel.swift
//  Still App
//
//  Cycles through inhale/hold/exhale/rest phases and drives
//  the breathing ring animation.
//

import Foundation
import Combine

@MainActor
final class BreathingGuideViewModel: ObservableObject {
    enum PhaseType: String {
        case inhale
        case hold
        case exhale
        case rest

        var displayName: String {
            rawValue.capitalized
        }

        var guidance: String {
            switch self {
            case .inhale: return "Breathe in"
            case .hold: return "Hold"
            case .exhale: return "Slowly breathe out"
            case .rest: return "Rest"
            }
        }
    }

    struct Phase {
        let type: PhaseType
        let duration: TimeInterval
    }

    @Published private(set) var phase: PhaseType
    @Published private(set) var phaseProgress: Double

    private let phases: [Phase]
    private let timerProvider: TimerProviding
    private let haptics: HapticProviding
    private var timer: AnyCancellable?

    private let tickInterval: TimeInterval = 0.1
    private var currentIndex: Int = 0
    private var elapsed: TimeInterval = 0

    init(
        phases: [Phase] = [
            Phase(type: .inhale, duration: 4),
            Phase(type: .hold, duration: 2),
            Phase(type: .exhale, duration: 4),
            Phase(type: .rest, duration: 2)
        ],
        timerProvider: TimerProviding = DefaultTimerProvider(),
        haptics: HapticProviding = DefaultHapticProvider()
    ) {
        self.phases = phases
        self.timerProvider = timerProvider
        self.haptics = haptics
        self.phase = phases.first?.type ?? .inhale
        self.phaseProgress = 0
    }

    func start() {
        guard timer == nil else { return }
        haptics.prepare()
        reset(to: 0, triggerHaptic: false)
        timer = timerProvider.publisher(every: tickInterval)
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    func stop() {
        timer?.cancel()
        timer = nil
        phaseProgress = 0
        elapsed = 0
    }

    private func tick() {
        guard !phases.isEmpty else { return }
        let phase = phases[currentIndex]
        elapsed += tickInterval
        let progress = min(elapsed / phase.duration, 1)
        phaseProgress = progress

        if elapsed >= phase.duration {
            let nextIndex = (currentIndex + 1) % phases.count
            reset(to: nextIndex, triggerHaptic: true)
        }
    }

    private func reset(to index: Int, triggerHaptic: Bool) {
        currentIndex = index
        elapsed = 0
        phase = phases[index].type
        phaseProgress = 0

        if triggerHaptic {
            haptics.prepare()
            haptics.pulse()
        }
    }
}
