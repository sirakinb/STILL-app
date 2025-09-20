//
//  HomeViewModel.swift
//  Still App
//
//  Drives the home screen preset selector and creates sessions
//  from the user's chosen duration.
//

import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var selectedPresetKind: SessionPreset.Kind
    @Published var customMinutes: Int

    let presets: [SessionPreset] = [
        SessionPreset(kind: .fixed(minutes: 3)),
        SessionPreset(kind: .fixed(minutes: 5)),
        SessionPreset(kind: .fixed(minutes: 10)),
        SessionPreset(kind: .custom)
    ]

    init(defaultCustomMinutes: Int = 15) {
        selectedPresetKind = .fixed(minutes: 5)
        customMinutes = max(1, min(defaultCustomMinutes, 60))
    }

    var selectedDuration: TimeInterval {
        switch selectedPresetKind {
        case .fixed(let minutes):
            return TimeInterval(minutes * 60)
        case .custom:
            let minutes = max(1, min(customMinutes, 90))
            return TimeInterval(minutes * 60)
        }
    }

    var selectedLabel: String {
        switch selectedPresetKind {
        case .fixed(let minutes):
            return "\(minutes) Minute Session"
        case .custom:
            let minutes = max(1, min(customMinutes, 90))
            return "Custom Session (\(minutes) min)"
        }
    }

    func session() -> MeditationSession {
        let duration = selectedDuration
        let title: String

        switch selectedPresetKind {
        case .fixed(let minutes):
            title = "\(minutes) Minute Reset"
        case .custom:
            title = "Custom Calm"
        }

        return MeditationSession(title: title, duration: duration)
    }
}
