//
//  AudioManager.swift
//  Still App
//
//  Provides a lightweight audio engine that can loop ambient beds
//  and trigger short chimes without blocking the UI.
//

import Foundation
import AVFoundation

protocol AudioManaging {
    func configureAudioSession()
    func preload(_ asset: SoundAsset)
    func playAmbient(asset: SoundAsset, volume: Float, loops: Bool)
    func stopAmbient(fadeDuration: TimeInterval)
    func playChime(asset: SoundAsset, volume: Float)
}

final class AudioManager: AudioManaging {
    static let shared = AudioManager()

    private let engine = AVAudioEngine()
    private let ambientPlayer = AVAudioPlayerNode()
    private let chimePlayer = AVAudioPlayerNode()
    private var buffers: [SoundAsset: AVAudioPCMBuffer] = [:]

    private init() {
        engine.attach(ambientPlayer)
        engine.attach(chimePlayer)

        let mixer = engine.mainMixerNode
        engine.connect(ambientPlayer, to: mixer, format: nil)
        engine.connect(chimePlayer, to: mixer, format: nil)
    }

    func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, options: [.mixWithOthers])
            try session.setActive(true, options: [])
        } catch {
            print("[Audio] Failed to configure session: \(error.localizedDescription)")
        }
    }

    func preload(_ asset: SoundAsset) {
        _ = buffer(for: asset)
    }

    func playAmbient(asset: SoundAsset, volume: Float, loops: Bool) {
        guard let buffer = buffer(for: asset) else { return }
        startEngineIfNeeded()
        ambientPlayer.stop()
        ambientPlayer.volume = volume
        ambientPlayer.play()
        let options: AVAudioPlayerNodeBufferOptions = loops ? [.loops] : []
        ambientPlayer.scheduleBuffer(buffer, at: nil, options: options, completionHandler: nil)
    }

    func stopAmbient(fadeDuration: TimeInterval = 0.8) {
        guard ambientPlayer.isPlaying else { return }
        if fadeDuration <= 0 {
            ambientPlayer.stop()
            return
        }

        let steps = 20
        let startVolume = ambientPlayer.volume
        let stepTime = fadeDuration / Double(steps)

        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepTime * Double(i)) { [weak self] in
                guard let self = self else { return }
                let factor = Float(Double(steps - i) / Double(steps))
                self.ambientPlayer.volume = startVolume * factor

                if i == steps {
                    self.ambientPlayer.stop()
                    self.ambientPlayer.volume = startVolume
                }
            }
        }
    }

    func playChime(asset: SoundAsset, volume: Float) {
        guard let buffer = buffer(for: asset) else { return }
        startEngineIfNeeded()
        chimePlayer.volume = volume
        chimePlayer.stop()
        chimePlayer.play()
        chimePlayer.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }

    // MARK: - Helpers

    private func buffer(for asset: SoundAsset) -> AVAudioPCMBuffer? {
        if let cached = buffers[asset] {
            return cached
        }

        guard let url = Bundle.main.url(forResource: asset.rawValue, withExtension: nil) else {
            print("[Audio] Missing resource: \(asset.rawValue)")
            return nil
        }

        do {
            let file = try AVAudioFile(forReading: url)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                                frameCapacity: AVAudioFrameCount(file.length)) else {
                return nil
            }
            try file.read(into: buffer)
            buffers[asset] = buffer
            return buffer
        } catch {
            print("[Audio] Unable to load \(asset.rawValue): \(error.localizedDescription)")
            return nil
        }
    }

    private func startEngineIfNeeded() {
        guard !engine.isRunning else { return }
        do {
            try engine.start()
        } catch {
            print("[Audio] Engine failed to start: \(error.localizedDescription)")
        }
    }
}
