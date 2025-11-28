//
//  SavedMusicStore.swift
//  Still App
//
//  Store for managing generated music saved to the library.
//

import Foundation

@MainActor
final class SavedMusicStore: ObservableObject {
    static let shared = SavedMusicStore()
    
    @Published private(set) var savedTracks: [GeneratedMusic] = []
    
    private let userDefaultsKey = "savedMusicLibrary"
    
    private init() {
        loadTracks()
    }
    
    func saveToLibrary(_ track: GeneratedMusic) {
        // Check if already saved
        guard !savedTracks.contains(where: { $0.id == track.id }) else {
            return
        }
        
        savedTracks.insert(track, at: 0)
        persistTracks()
    }
    
    func removeFromLibrary(_ track: GeneratedMusic) {
        savedTracks.removeAll { $0.id == track.id }
        persistTracks()
    }
    
    func isInLibrary(_ track: GeneratedMusic) -> Bool {
        savedTracks.contains { $0.id == track.id }
    }
    
    private func loadTracks() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let tracks = try? JSONDecoder().decode([GeneratedMusic].self, from: data) {
            savedTracks = tracks
        }
    }
    
    private func persistTracks() {
        if let encoded = try? JSONEncoder().encode(savedTracks) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
}

