//
//  AppSettingsStore.swift
//  Still App
//
//  Centralised observable settings container for audio preferences.
//  Persists to UserDefaults so preferences survive relaunches.
//

import Foundation

protocol SettingsStoring {
    func object(forKey defaultName: String) -> Any?
    func set(_ value: Any?, forKey defaultName: String)
}

extension UserDefaults: SettingsStoring {}

@MainActor
final class AppSettingsStore: ObservableObject {
    @Published var selectedSoundscape: SoundscapeOption {
        didSet { storage.set(selectedSoundscape.rawValue, forKey: Keys.soundscape) }
    }

    @Published var ambientVolume: Double {
        didSet {
            let clamped = min(max(ambientVolume, 0), 1)
            if ambientVolume != clamped {
                ambientVolume = clamped
                return
            }
            storage.set(clamped, forKey: Keys.ambientVolume)
        }
    }

    @Published var startChimeEnabled: Bool {
        didSet { storage.set(startChimeEnabled, forKey: Keys.startChime) }
    }

    @Published var endChimeEnabled: Bool {
        didSet { storage.set(endChimeEnabled, forKey: Keys.endChime) }
    }

    @Published var voiceGuidanceEnabled: Bool {
        didSet { storage.set(voiceGuidanceEnabled, forKey: Keys.voiceGuidance) }
    }

    private let storage: SettingsStoring

    init(storage: SettingsStoring = UserDefaults.standard) {
        self.storage = storage
        selectedSoundscape = AppSettingsStore.resolveSoundscape(from: storage.object(forKey: Keys.soundscape))
        ambientVolume = AppSettingsStore.resolveDouble(from: storage.object(forKey: Keys.ambientVolume), defaultValue: 0.35)
        startChimeEnabled = AppSettingsStore.resolveBool(from: storage.object(forKey: Keys.startChime), defaultValue: true)
        endChimeEnabled = AppSettingsStore.resolveBool(from: storage.object(forKey: Keys.endChime), defaultValue: true)
        voiceGuidanceEnabled = AppSettingsStore.resolveBool(from: storage.object(forKey: Keys.voiceGuidance), defaultValue: false)
    }
}

private extension AppSettingsStore {
    enum Keys {
        static let soundscape = "settings.soundscape"
        static let ambientVolume = "settings.ambientVolume"
        static let startChime = "settings.startChime"
        static let endChime = "settings.endChime"
        static let voiceGuidance = "settings.voiceGuidance"
    }

    static func resolveSoundscape(from object: Any?) -> SoundscapeOption {
        if let raw = object as? String, let option = SoundscapeOption(rawValue: raw) {
            return option
        }
        return .rain
    }

    static func resolveDouble(from object: Any?, defaultValue: Double) -> Double {
        guard let value = object as? Double else { return defaultValue }
        return min(max(value, 0), 1)
    }

    static func resolveBool(from object: Any?, defaultValue: Bool) -> Bool {
        if let value = object as? Bool { return value }
        return defaultValue
    }
}
