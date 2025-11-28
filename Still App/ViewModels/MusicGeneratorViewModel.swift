//
//  MusicGeneratorViewModel.swift
//  Still App
//
//  ViewModel for the meditation music generator feature.
//

import SwiftUI
import AVFoundation
import CoreMedia

@MainActor
class MusicGeneratorViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var prompt: String = ""
    @Published var customStyle: String = ""
    @Published var selectedStyle: MeditationStyle = .ambient
    @Published var title: String = ""
    @Published var isInstrumental: Bool = true
    
    @Published var isGenerating: Bool = false
    @Published var generationProgress: String = ""
    @Published var errorMessage: String?
    
    @Published var generatedTracks: [GeneratedMusic] = []
    @Published var currentlyPlayingId: String?
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isBuffering: Bool = false
    
    // MARK: - Private Properties
    
    private var audioPlayer: AVPlayer?
    private var timeObserver: Any?
    private let userDefaultsKey = "generatedMusicTracks"
    
    // MARK: - Init
    
    init() {
        loadSavedTracks()
    }
    
    // MARK: - Computed Properties
    
    var effectiveStyle: String {
        if selectedStyle == .custom {
            return customStyle.isEmpty ? "Ambient, Peaceful, Meditation" : customStyle
        }
        return selectedStyle.rawValue
    }
    
    var canGenerate: Bool {
        !prompt.isEmpty && !title.isEmpty && !isGenerating
    }
    
    // MARK: - Generation
    
    func generateMusic() async {
        guard canGenerate else { return }
        
        isGenerating = true
        errorMessage = nil
        generationProgress = "Starting generation..."
        
        do {
            // Step 1: Submit generation request
            generationProgress = "Submitting request to Suno AI..."
            let taskId = try await SunoAPIService.shared.generateMusic(
                prompt: prompt,
                style: effectiveStyle,
                title: title,
                instrumental: isInstrumental
            )
            
            // Step 2: Poll for completion
            generationProgress = "Creating your meditation music..."
            let result = try await SunoAPIService.shared.waitForCompletion(taskId: taskId)
            
            // Step 3: Process result
            generationProgress = "Finalizing..."
            
            // Debug: print full result
            print("=== Full API Result ===")
            print("Status: \(result.status ?? "nil")")
            print("AudioUrl direct: \(result.audioUrl ?? "nil")")
            
            // Extract audio URL using the helper method
            let (audioUrl, imageUrl) = SunoAPIService.shared.extractAudioUrl(from: result)
            
            print("Extracted audioUrl: \(audioUrl ?? "nil")")
            print("Extracted imageUrl: \(imageUrl ?? "nil")")
            
            // If no audio URL, show error but still save for retry later
            if audioUrl == nil {
                print("WARNING: No audio URL found in response!")
            }
            
            let newTrack = GeneratedMusic(
                id: taskId,
                title: title,
                style: effectiveStyle,
                prompt: prompt,
                audioUrl: audioUrl,
                imageUrl: imageUrl,
                createdAt: Date()
            )
            
            generatedTracks.insert(newTrack, at: 0)
            saveTracks()
            
            // Clear form
            prompt = ""
            title = ""
            generationProgress = ""
            
        } catch {
            errorMessage = error.localizedDescription
            generationProgress = ""
        }
        
        isGenerating = false
    }
    
    // MARK: - Playback
    
    func playTrack(_ track: GeneratedMusic) {
        guard let urlString = track.audioUrl, let url = URL(string: urlString) else {
            errorMessage = "No audio URL available"
            return
        }
        
        print("Playing track from URL: \(urlString)")
        
        // Stop current playback
        stopPlayback()
        
        // Configure audio session for playback at maximum volume
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            // Try to boost output volume
            try audioSession.overrideOutputAudioPort(.speaker)
            
            print("Audio session configured successfully")
        } catch {
            print("Audio session error: \(error)")
            // Continue anyway - playback might still work
        }
        
        // Create and play at maximum volume
        let playerItem = AVPlayerItem(url: url)
        audioPlayer = AVPlayer(playerItem: playerItem)
        audioPlayer?.volume = 1.0  // Maximum volume
        
        // Apply audio mix for boosted volume
        let audioMix = AVMutableAudioMix()
        let audioMixInputParameters = AVMutableAudioMixInputParameters(track: nil)
        audioMixInputParameters.setVolume(1.0, at: .zero)
        audioMix.inputParameters = [audioMixInputParameters]
        playerItem.audioMix = audioMix
        
        audioPlayer?.play()
        currentlyPlayingId = track.id
        
        print("Player started, status: \(audioPlayer?.status.rawValue ?? -1)")
        
        // Add periodic time observer for progress tracking
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = audioPlayer?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds
            
            // Update duration if available
            if let duration = self.audioPlayer?.currentItem?.duration.seconds,
               !duration.isNaN && !duration.isInfinite {
                self.duration = duration
            }
        }
        
        // Observe when playback ends
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.currentlyPlayingId = nil
        }
        
        // Observe for errors
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] notification in
            if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error {
                print("Playback error: \(error)")
                self?.errorMessage = "Playback failed: \(error.localizedDescription)"
            }
            self?.currentlyPlayingId = nil
        }
    }
    
    func stopPlayback() {
        // Remove time observer
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
    
    func seekForward(_ seconds: Double = 15) {
        let newTime = min(currentTime + seconds, duration)
        seek(to: newTime)
    }
    
    func seekBackward(_ seconds: Double = 15) {
        let newTime = max(currentTime - seconds, 0)
        seek(to: newTime)
    }
    
    func togglePlayback(for track: GeneratedMusic) {
        if currentlyPlayingId == track.id {
            stopPlayback()
        } else {
            playTrack(track)
        }
    }
    
    // MARK: - Track Management
    
    func deleteTrack(_ track: GeneratedMusic) {
        if currentlyPlayingId == track.id {
            stopPlayback()
        }
        generatedTracks.removeAll { $0.id == track.id }
        saveTracks()
    }
    
    func refreshTrack(_ track: GeneratedMusic) async {
        do {
            let details = try await SunoAPIService.shared.checkTaskStatus(taskId: track.id)
            let (audioUrl, imageUrl) = SunoAPIService.shared.extractAudioUrl(from: details)
            
            if let index = generatedTracks.firstIndex(where: { $0.id == track.id }) {
                generatedTracks[index] = GeneratedMusic(
                    id: track.id,
                    title: track.title,
                    style: track.style,
                    prompt: track.prompt,
                    audioUrl: audioUrl ?? track.audioUrl,
                    imageUrl: imageUrl ?? track.imageUrl,
                    createdAt: track.createdAt
                )
                saveTracks()
            }
        } catch {
            print("Failed to refresh track: \(error)")
        }
    }
    
    // MARK: - Persistence
    
    private func saveTracks() {
        if let encoded = try? JSONEncoder().encode(generatedTracks) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadSavedTracks() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let tracks = try? JSONDecoder().decode([GeneratedMusic].self, from: data) {
            generatedTracks = tracks
        }
    }
    
    // MARK: - Suggestions
    
    static let promptSuggestions = [
        "Gentle waves washing over a peaceful shore at sunrise",
        "A quiet forest with soft rain and distant birdsong",
        "Deep breathing exercise with calming tones",
        "Floating through clouds on a warm summer day",
        "Ancient temple bells echoing in mountain valleys",
        "Soft moonlight reflecting on a still lake",
        "A cozy fireplace crackling on a winter evening",
        "Morning dew drops in a zen garden"
    ]
}

