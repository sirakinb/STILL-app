//
//  MeditationSessionView.swift
//  Still App
//
//  Created by Akinyemi Bajulaiye on 9/20/25.
//

import SwiftUI

struct MeditationSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var historyStore: SessionHistoryStore

    let session: MeditationSession
    private let soundscapeOverride: SoundscapeOption?

    @ObservedObject private var settings: AppSettingsStore
    @StateObject private var timerViewModel: SessionTimerViewModel
    @StateObject private var audioController: SessionAudioController
    @State private var isPulsing = false
    @State private var startedAt = Date()
    @State private var pendingElapsedSeconds: Int?
    @State private var isEndingEarly = false
    @State private var summary: SessionSummary?

    init(session: MeditationSession, settings: AppSettingsStore, soundscapeOverride: SoundscapeOption? = nil) {
        self.session = session
        self.settings = settings
        self.soundscapeOverride = soundscapeOverride
        _timerViewModel = StateObject(wrappedValue: SessionTimerViewModel(duration: session.duration))
        _audioController = StateObject(wrappedValue: SessionAudioController(settings: settings, soundscapeOverride: soundscapeOverride))
    }

    var body: some View {
        CalmBackgroundView()
            .overlay {
                VStack(spacing: 32) {
                    Spacer()

                    VStack(spacing: 8) {
                        Text(session.title.uppercased())
                            .font(.headline)
                            .tracking(2)
                            .foregroundStyle(Color.stillSecondaryText)
                        Text("Stay present and breathe")
                            .font(.footnote)
                            .foregroundStyle(Color.stillSecondaryText.opacity(0.8))
                    }

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
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Time remaining")
                    .accessibilityValue(formattedTimeSpoken)

                    if let soundscape = soundscapeDescription {
                        Text(soundscape)
                            .font(.caption)
                            .foregroundStyle(Color.stillSecondaryText.opacity(0.7))
                    }

                    Spacer()

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
                    .accessibilityHint("End the meditation early")

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
            .onChange(of: settings.selectedSoundscape) { _ in
                guard soundscapeOverride == nil else { return }
                audioController.refreshAmbient()
            }
            .onChange(of: settings.ambientVolume) { _ in
                guard soundscapeOverride == nil else { return }
                audioController.refreshAmbient()
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
        guard session.duration > 0 else { return 0 }
        return Double(timerViewModel.remainingSeconds) / session.duration
    }

    private var formattedTime: String {
        let minutes = timerViewModel.remainingSeconds / 60
        let seconds = timerViewModel.remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var formattedTimeSpoken: String {
        let minutes = timerViewModel.remainingSeconds / 60
        let seconds = timerViewModel.remainingSeconds % 60
        return "\(minutes) minutes and \(seconds) seconds remaining"
    }

    private func endSession() {
        let elapsed = max(timerViewModel.elapsedSeconds, 0)
        pendingElapsedSeconds = elapsed
        isEndingEarly = true
        audioController.stopImmediately()
        timerViewModel.endEarly()
    }

    private var soundscapeDescription: String? {
        guard let option = effectiveSoundscape else {
            return nil
        }
        if settings.ambientVolume <= 0 {
            return "Soundscape muted"
        }
        if option == .none {
            return "Soundscape: Silence"
        }
        return "Soundscape: \(option.displayName)"
    }

    private var effectiveSoundscape: SoundscapeOption? {
        soundscapeOverride ?? settings.selectedSoundscape
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
            soundscape: effectiveSoundscape,
            startedAt: startedAt
        )

        historyStore.record(
            session: session,
            startedAt: startedAt,
            actualDurationSeconds: summary.actualDurationSeconds,
            completedNaturally: didFinishNaturally,
            endedEarly: !didFinishNaturally,
            soundscape: effectiveSoundscape
        )

        self.summary = summary
    }
}

#Preview {
    NavigationStack {
        MeditationSessionView(session: .fiveMinuteReset, settings: AppSettingsStore())
    }
    .environmentObject(SessionHistoryStore())
}
