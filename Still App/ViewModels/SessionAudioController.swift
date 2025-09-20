//
//  SessionAudioController.swift
//  Still App
//
//  Coordinates audio playback during a meditation session based on settings.
//

import Foundation

@MainActor
final class SessionAudioController: ObservableObject {
    private let settings: AppSettingsStore
    private let audioManager: AudioManaging
    private let soundscapeOverride: SoundscapeOption?

    init(settings: AppSettingsStore, soundscapeOverride: SoundscapeOption? = nil, audioManager: AudioManaging = AudioManager.shared) {
        self.settings = settings
        self.audioManager = audioManager
        self.soundscapeOverride = soundscapeOverride
    }

    func prepareForSession() {
        audioManager.configureAudioSession()
        preloadAssets()
        playStartChimeIfNeeded()
        startAmbientIfNeeded()
    }

    func handleSessionCompletion(didFinishNaturally: Bool) {
        if didFinishNaturally {
            playEndChimeIfNeeded()
        }
        audioManager.stopAmbient(fadeDuration: 0.6)
    }

    func stopImmediately() {
        audioManager.stopAmbient(fadeDuration: 0)
    }

    func refreshAmbient() {
        startAmbientIfNeeded()
    }

    private func preloadAssets() {
        if let ambient = effectiveSoundscape?.asset {
            audioManager.preload(ambient)
        }
        audioManager.preload(.startChime)
        audioManager.preload(.endChime)
    }

    private func startAmbientIfNeeded() {
        guard
            let option = effectiveSoundscape,
            let asset = option.asset,
            settings.ambientVolume > 0
        else {
            audioManager.stopAmbient(fadeDuration: 0.4)
            return
        }

        audioManager.playAmbient(
            asset: asset,
            volume: Float(settings.ambientVolume),
            loops: option.loopsIndefinitely
        )
    }

    private func playStartChimeIfNeeded() {
        guard settings.startChimeEnabled else { return }
        audioManager.playChime(asset: .startChime, volume: 0.8)
    }

    private func playEndChimeIfNeeded() {
        guard settings.endChimeEnabled else { return }
        audioManager.playChime(asset: .endChime, volume: 1.0)
    }

    private var effectiveSoundscape: SoundscapeOption? {
        soundscapeOverride ?? settings.selectedSoundscape
    }
}
