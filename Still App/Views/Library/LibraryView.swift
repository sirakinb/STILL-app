//
//  LibraryView.swift
//  Still App
//
//  Curated collection of tracks and soundscapes for intentional sessions.
//

import SwiftUI
import AVFoundation

struct LibraryView: View {
    @EnvironmentObject private var settings: AppSettingsStore
    @ObservedObject private var savedMusicStore = SavedMusicStore.shared
    @StateObject private var previewPlayer = LibraryMusicPlayerViewModel()
    
    @State private var navigationPath: [LibraryDestination] = []
    @State private var selectedTrackForSession: GeneratedMusic?
    @State private var showDurationPicker = false

    private let defaultItems = MeditationContent.featured

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                CalmBackgroundView()

                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Section header for default content
                        if !defaultItems.isEmpty {
                            sectionHeader("Still Creations")
                            
                            ForEach(defaultItems) { item in
                                DefaultMeditationRow(content: item) {
                                    startSession(for: item)
                                }
                            }
                        }
                        
                        // Section header for custom music
                        if !savedMusicStore.savedTracks.isEmpty {
                            sectionHeader("My Creations")
                                .padding(.top, 8)
                            
                            ForEach(savedMusicStore.savedTracks) { track in
                                CustomMusicRow(
                                    track: track,
                                    isPlaying: previewPlayer.currentlyPlayingId == track.id,
                                    onPreview: { previewPlayer.togglePlayback(for: track) },
                                    onMeditate: {
                                        previewPlayer.stopPlayback()
                                        selectedTrackForSession = track
                                        showDurationPicker = true
                                    },
                                    onRemove: { savedMusicStore.removeFromLibrary(track) }
                                )
                            }
                        }
                        
                        // Empty state hint if no custom music
                        if savedMusicStore.savedTracks.isEmpty {
                            addMusicHint
                                .padding(.top, 16)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
            }
            .navigationDestination(for: LibraryDestination.self) { destination in
                switch destination {
                case .defaultSession(let configuration):
                    MeditationSessionView(
                        session: configuration.session,
                        settings: settings,
                        soundscapeOverride: configuration.soundscape
                    )
                case .generatedSession(let track, let duration):
                    GeneratedMusicSessionView(track: track, durationMinutes: duration, settings: settings)
                }
            }
            .navigationTitle("Library")
            .sheet(isPresented: $showDurationPicker) {
                if let track = selectedTrackForSession {
                    DurationPickerSheet(track: track) { duration in
                        showDurationPicker = false
                        navigationPath.append(.generatedSession(track: track, duration: duration))
                    }
                    .presentationDetents([.medium])
                }
            }
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.stillSecondaryText)
                .textCase(.uppercase)
                .tracking(1)
            Spacer()
        }
        .padding(.top, 16)
        .padding(.bottom, 4)
    }
    
    private var addMusicHint: some View {
        HStack(spacing: 12) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 20))
                .foregroundStyle(Color.stillAccent)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Create Your Own")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.stillPrimaryText)
                Text("Generate custom meditation music in the Create tab")
                    .font(.caption)
                    .foregroundStyle(Color.stillSecondaryText)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.stillOverlay.opacity(0.3))
                .strokeBorder(Color.stillAccent.opacity(0.3), lineWidth: 1, antialiased: true)
        )
    }

    private func startSession(for content: MeditationContent) {
        let session = MeditationSession(
            title: content.title,
            duration: TimeInterval(content.durationMinutes * 60)
        )
        let configuration = SessionConfiguration(session: session, soundscape: content.soundscape)
        navigationPath.append(.defaultSession(configuration))
    }
}

// MARK: - Navigation Destinations
enum LibraryDestination: Hashable {
    case defaultSession(SessionConfiguration)
    case generatedSession(track: GeneratedMusic, duration: Int)
}

struct SessionConfiguration: Hashable {
    let session: MeditationSession
    let soundscape: SoundscapeOption
}

// MARK: - Default Meditation Row
struct DefaultMeditationRow: View {
    let content: MeditationContent
    let onMeditate: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.stillAccent.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: iconForSoundscape(content.soundscape))
                    .font(.system(size: 20))
                    .foregroundStyle(Color.stillAccent)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(content.title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.stillPrimaryText)
                
                Text(content.subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.stillSecondaryText)
            }
            
            Spacer()
            
            // Duration badge
            Text(content.durationText)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.stillSecondaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.stillOverlay.opacity(0.5))
                .clipShape(Capsule())
            
            // Meditate button
            Button(action: onMeditate) {
                Image(systemName: "play.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.stillAccent)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.9))
                .shadow(color: Color.stillDeepBlue.opacity(0.05), radius: 10, y: 4)
        )
    }
    
    private func iconForSoundscape(_ soundscape: SoundscapeOption) -> String {
        switch soundscape {
        case .ocean: return "water.waves"
        case .rain: return "cloud.rain"
        case .meditationA: return "sunrise"
        case .meditationB: return "moon.stars"
        case .none: return "speaker.slash"
        }
    }
}

// MARK: - Custom Music Row
struct CustomMusicRow: View {
    let track: GeneratedMusic
    let isPlaying: Bool
    let onPreview: () -> Void
    let onMeditate: () -> Void
    let onRemove: () -> Void
    
    @State private var showRemoveConfirm = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Preview button
            Button(action: onPreview) {
                ZStack {
                    Circle()
                        .fill(isPlaying ? Color.stillAccent : Color.stillAccent.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: isPlaying ? "pause.fill" : "waveform")
                        .font(.system(size: isPlaying ? 16 : 20))
                        .foregroundStyle(isPlaying ? .white : Color.stillAccent)
                }
            }
            .buttonStyle(.plain)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.stillPrimaryText)
                
                Text(track.style.components(separatedBy: ",").first ?? "Custom")
                    .font(.caption)
                    .foregroundStyle(Color.stillSecondaryText)
            }
            
            Spacer(minLength: 8)
            
            // Meditate button
            Button(action: onMeditate) {
                Image(systemName: "play.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.stillAccent)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            
            // Remove button
            Button {
                showRemoveConfirm = true
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.stillSecondaryText)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.9))
                .shadow(color: Color.stillDeepBlue.opacity(0.05), radius: 10, y: 4)
        )
        .alert("Remove from Library?", isPresented: $showRemoveConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) { onRemove() }
        }
    }
}

// MARK: - Duration Picker Sheet
struct DurationPickerSheet: View {
    let track: GeneratedMusic
    let onSelect: (Int) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    private let durations = [3, 5, 10, 15, 20, 30]
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("Start Meditation")
                    .font(.system(size: 22, weight: .medium, design: .serif))
                    .foregroundStyle(Color.stillPrimaryText)
                
                Text(track.title)
                    .font(.subheadline)
                    .foregroundStyle(Color.stillSecondaryText)
            }
            .padding(.top, 24)
            
            Text("Choose session length")
                .font(.subheadline)
                .foregroundStyle(Color.stillSecondaryText)
            
            // Duration options
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(durations, id: \.self) { duration in
                    Button {
                        onSelect(duration)
                    } label: {
                        VStack(spacing: 4) {
                            Text("\(duration)")
                                .font(.system(size: 28, weight: .light, design: .rounded))
                            Text("min")
                                .font(.caption)
                        }
                        .foregroundStyle(Color.stillPrimaryText)
                        .frame(width: 80, height: 80)
                        .background(Color.stillOverlay.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            Button("Cancel") {
                dismiss()
            }
            .font(.body)
            .foregroundStyle(Color.stillSecondaryText)
            .padding(.bottom, 24)
        }
        .background(Color.stillBackground)
    }
}

// MARK: - Library Music Player ViewModel
@MainActor
class LibraryMusicPlayerViewModel: ObservableObject {
    @Published var currentlyPlayingId: String?
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    
    private var audioPlayer: AVPlayer?
    private var timeObserver: Any?
    
    func togglePlayback(for track: GeneratedMusic) {
        if currentlyPlayingId == track.id {
            stopPlayback()
        } else {
            playTrack(track)
        }
    }
    
    func playTrack(_ track: GeneratedMusic) {
        guard let urlString = track.audioUrl, let url = URL(string: urlString) else { return }
        
        stopPlayback()
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
        
        let playerItem = AVPlayerItem(url: url)
        audioPlayer = AVPlayer(playerItem: playerItem)
        audioPlayer?.volume = 1.0
        audioPlayer?.play()
        currentlyPlayingId = track.id
        
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = audioPlayer?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds
            if let duration = self.audioPlayer?.currentItem?.duration.seconds,
               !duration.isNaN && !duration.isInfinite {
                self.duration = duration
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.currentlyPlayingId = nil
        }
    }
    
    func stopPlayback() {
        if let observer = timeObserver {
            audioPlayer?.removeTimeObserver(observer)
            timeObserver = nil
        }
        audioPlayer?.pause()
        audioPlayer = nil
        currentlyPlayingId = nil
        currentTime = 0
        duration = 0
    }
    
    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        audioPlayer?.seek(to: cmTime)
    }
}

#Preview {
    LibraryView()
        .environmentObject(AppSettingsStore())
        .environmentObject(SessionHistoryStore())
}
