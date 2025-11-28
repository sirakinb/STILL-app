//
//  GeneratedMusicSessionView.swift
//  Still App
//
//  Meditation session view that uses generated music as the background audio.
//

import SwiftUI
import AVFoundation

struct GeneratedMusicSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var historyStore: SessionHistoryStore
    
    let track: GeneratedMusic
    let durationMinutes: Int
    
    @ObservedObject private var settings: AppSettingsStore
    @StateObject private var timerViewModel: SessionTimerViewModel
    @StateObject private var audioController: GeneratedMusicAudioController
    
    @State private var isPulsing = false
    @State private var startedAt = Date()
    @State private var pendingElapsedSeconds: Int?
    @State private var isEndingEarly = false
    @State private var summary: SessionSummary?
    
    init(track: GeneratedMusic, durationMinutes: Int, settings: AppSettingsStore) {
        self.track = track
        self.durationMinutes = durationMinutes
        self.settings = settings
        
        let duration = TimeInterval(durationMinutes * 60)
        _timerViewModel = StateObject(wrappedValue: SessionTimerViewModel(duration: duration))
        _audioController = StateObject(wrappedValue: GeneratedMusicAudioController(
            audioUrl: track.audioUrl,
            settings: settings
        ))
    }
    
    private var session: MeditationSession {
        MeditationSession(title: track.title, duration: TimeInterval(durationMinutes * 60))
    }
    
    var body: some View {
        CalmBackgroundView()
            .overlay {
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Header
                    VStack(spacing: 8) {
                        Text(track.title.uppercased())
                            .font(.headline)
                            .tracking(2)
                            .foregroundStyle(Color.stillSecondaryText)
                        
                        Text(track.style.components(separatedBy: ",").first ?? "Custom Music")
                            .font(.footnote)
                            .foregroundStyle(Color.stillSecondaryText.opacity(0.8))
                    }
                    
                    // Timer circle
                    ZStack {
                        Circle()
                            .stroke(Color.stillOverlay.opacity(0.25), lineWidth: 18)
                            .scaleEffect(isPulsing ? 1.05 : 0.95)
                            .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: isPulsing)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(progress))
                            .stroke(Color.stillAccent, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.3), value: timerViewModel.remainingSeconds)
                        
                        Text(formattedTime)
                            .font(.system(size: 48, weight: .light, design: .rounded))
                            .foregroundStyle(Color.stillPrimaryText)
                            .monospacedDigit()
                    }
                    .frame(width: 220, height: 220)
                    
                    // Music indicator
                    HStack(spacing: 8) {
                        Image(systemName: "waveform")
                            .font(.caption)
                        Text("Playing: \(track.title)")
                            .font(.caption)
                    }
                    .foregroundStyle(Color.stillSecondaryText.opacity(0.7))
                    
                    Spacer()
                    
                    // End button
                    Button(action: endSession) {
                        Text("End Session")
                            .font(.headline)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.stillAccent)
                    .clipShape(Capsule())
                    .padding(.horizontal, 32)
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: endSession) {
                        Label("Close", systemImage: "xmark")
                    }
                    .tint(Color.stillSecondaryText)
                }
            }
            .onAppear {
                timerViewModel.start()
                isPulsing = true
                startedAt = Date()
                audioController.prepareForSession()
            }
            .onChange(of: timerViewModel.remainingSeconds) { newValue in
                if newValue == 0 {
                    handleCompletion(didFinishNaturally: !isEndingEarly)
                    isEndingEarly = false
                }
            }
            .onDisappear {
                timerViewModel.reset()
                isPulsing = false
                audioController.stopImmediately()
            }
            .sheet(item: $summary) { summary in
                SessionSummaryView(summary: summary) {
                    dismiss()
                }
                .presentationDetents([.medium])
                .interactiveDismissDisabled()
            }
    }
    
    private var progress: Double {
        let totalDuration = TimeInterval(durationMinutes * 60)
        guard totalDuration > 0 else { return 0 }
        return Double(timerViewModel.remainingSeconds) / totalDuration
    }
    
    private var formattedTime: String {
        let minutes = timerViewModel.remainingSeconds / 60
        let seconds = timerViewModel.remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func endSession() {
        let elapsed = max(timerViewModel.elapsedSeconds, 0)
        pendingElapsedSeconds = elapsed
        isEndingEarly = true
        audioController.stopImmediately()
        timerViewModel.endEarly()
    }
    
    private func handleCompletion(didFinishNaturally: Bool) {
        let elapsed = pendingElapsedSeconds ?? (didFinishNaturally ? timerViewModel.totalDurationSeconds : timerViewModel.elapsedSeconds)
        pendingElapsedSeconds = nil
        
        audioController.handleSessionCompletion(didFinishNaturally: didFinishNaturally)
        
        let actualSeconds = didFinishNaturally ? timerViewModel.totalDurationSeconds : elapsed
        let summary = SessionSummary(
            session: session,
            actualDurationSeconds: max(0, actualSeconds),
            didFinishNaturally: didFinishNaturally,
            soundscape: nil,
            startedAt: startedAt
        )
        
        historyStore.record(
            session: session,
            startedAt: startedAt,
            actualDurationSeconds: summary.actualDurationSeconds,
            completedNaturally: didFinishNaturally,
            endedEarly: !didFinishNaturally,
            soundscape: nil
        )
        
        self.summary = summary
    }
}

// MARK: - Generated Music Audio Controller
@MainActor
final class GeneratedMusicAudioController: ObservableObject {
    private let audioUrl: String?
    private let settings: AppSettingsStore
    private var audioPlayer: AVPlayer?
    private var looper: AVPlayerLooper?
    private var queuePlayer: AVQueuePlayer?
    
    init(audioUrl: String?, settings: AppSettingsStore) {
        self.audioUrl = audioUrl
        self.settings = settings
    }
    
    func prepareForSession() {
        configureAudioSession()
        playStartChimeIfNeeded()
        
        // Delay music start slightly after chime
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.startGeneratedMusic()
        }
    }
    
    func handleSessionCompletion(didFinishNaturally: Bool) {
        // Fade out music
        fadeOutMusic()
        
        if didFinishNaturally {
            // Play end chime after fade
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                self?.playEndChimeIfNeeded()
            }
        }
    }
    
    func stopImmediately() {
        audioPlayer?.pause()
        queuePlayer?.pause()
        audioPlayer = nil
        queuePlayer = nil
        looper = nil
    }
    
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }
    
    private func startGeneratedMusic() {
        guard let urlString = audioUrl, let url = URL(string: urlString) else {
            print("No audio URL available for session")
            return
        }
        
        // Use AVQueuePlayer with looper for seamless looping
        let playerItem = AVPlayerItem(url: url)
        queuePlayer = AVQueuePlayer(playerItem: playerItem)
        
        if let queuePlayer = queuePlayer {
            looper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
            queuePlayer.volume = Float(settings.ambientVolume)
            queuePlayer.play()
        }
    }
    
    private func fadeOutMusic() {
        guard let player = queuePlayer else { return }
        
        let fadeSteps = 10
        let fadeInterval = 0.08
        let volumeStep = player.volume / Float(fadeSteps)
        
        for i in 0..<fadeSteps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * fadeInterval) {
                player.volume = max(0, player.volume - volumeStep)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(fadeSteps) * fadeInterval) { [weak self] in
            self?.queuePlayer?.pause()
        }
    }
    
    private func playStartChimeIfNeeded() {
        guard settings.startChimeEnabled else { return }
        AudioManager.shared.playChime(asset: .startChime, volume: 0.8)
    }
    
    private func playEndChimeIfNeeded() {
        guard settings.endChimeEnabled else { return }
        AudioManager.shared.playChime(asset: .endChime, volume: 1.0)
    }
}

#Preview {
    NavigationStack {
        GeneratedMusicSessionView(
            track: GeneratedMusic(
                id: "test",
                title: "Test Track",
                style: "Ambient",
                prompt: "Test",
                audioUrl: nil,
                imageUrl: nil,
                createdAt: Date()
            ),
            durationMinutes: 5,
            settings: AppSettingsStore()
        )
    }
    .environmentObject(SessionHistoryStore())
}

