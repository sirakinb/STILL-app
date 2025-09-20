//
//  SettingsView.swift
//  Still App
//
//  Provides audio and haptic controls for the meditation experience.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettingsStore
    @EnvironmentObject var historyStore: SessionHistoryStore
    @State private var previewing: Bool = false
    @State private var previewTask: Task<Void, Never>?

    var body: some View {
        List {
            soundscapeSection
            chimeSection
            guidanceSection
            progressSection
        }
        .navigationTitle("Settings")
        .onDisappear {
            previewTask?.cancel()
            AudioManager.shared.stopAmbient(fadeDuration: 0.4)
        }
    }

    private var soundscapeSection: some View {
        Section("Soundscape") {
            Picker("Background", selection: $settings.selectedSoundscape) {
                ForEach(SoundscapeOption.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: settings.selectedSoundscape) { _ in
                if previewing {
                    handlePreviewToggle(isOn: true)
                }
            }

            HStack {
                Text("Volume")
                Slider(value: $settings.ambientVolume, in: 0...1)
                    .accessibilityLabel("Ambient volume")
            }

            Toggle(isOn: $previewing) {
                Text("Preview soundscape")
            }
            .onChange(of: previewing) { isOn in
                handlePreviewToggle(isOn: isOn)
            }
        }
    }

    private var chimeSection: some View {
        Section("Chimes") {
            Toggle("Play start chime", isOn: $settings.startChimeEnabled)
            Toggle("Play end chime", isOn: $settings.endChimeEnabled)
        }
    }

    private var guidanceSection: some View {
        Section("Guidance") {
            Toggle("Voice guidance", isOn: $settings.voiceGuidanceEnabled)
                .disabled(true)
                .foregroundStyle(.secondary)
                .overlay(alignment: .trailing) {
                    Text("Coming soon")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .allowsHitTesting(false)
            }
        }
    }

    private func handlePreviewToggle(isOn: Bool) {
        previewTask?.cancel()

        guard isOn, let asset = settings.selectedSoundscape.asset else {
            AudioManager.shared.stopAmbient(fadeDuration: 0.3)
            return
        }

        let loops = settings.selectedSoundscape.loopsIndefinitely
        AudioManager.shared.configureAudioSession()
        AudioManager.shared.playAmbient(asset: asset, volume: Float(settings.ambientVolume), loops: loops)

        previewTask = Task { [settings] in
            let seconds = loops ? 15.0 : 10.0
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            AudioManager.shared.stopAmbient(fadeDuration: 0.6)
            await MainActor.run { previewing = false }
        }
    }

    private var progressSection: some View {
        Section("Progress") {
            HStack {
                Text("Current streak")
                Spacer()
                Text("\(historyStore.currentStreak) days")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Total minutes")
                Spacer()
                Text("\(historyStore.totalMinutes)")
                    .foregroundStyle(.secondary)
            }

            if let last = historyStore.sessions.first {
                HStack {
                    Text("Last session")
                    Spacer()
                    Text("\(last.actualMinutes) min · \(shortDateFormatter.string(from: last.startedAt))")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var shortDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AppSettingsStore())
            .environmentObject(SessionHistoryStore())
    }
}
