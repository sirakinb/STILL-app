//
//  MeditationContent.swift
//  Still App
//
//  Defines curated sessions that appear in the Library tab.
//

import Foundation

struct MeditationContent: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let description: String
    let durationMinutes: Int
    let soundscape: SoundscapeOption

    var durationText: String {
        "\(durationMinutes) min"
    }

    static let featured: [MeditationContent] = [
        MeditationContent(
            title: "Morning Focus",
            subtitle: "Ease into the day",
            description: "A gentle guided track to ground your attention before you step into the world.",
            durationMinutes: 10,
            soundscape: .meditationA
        ),
        MeditationContent(
            title: "Evening Unwind",
            subtitle: "Let go and soften",
            description: "Wind down with a soft voice-backed journey. Perfect before rest.",
            durationMinutes: 12,
            soundscape: .meditationB
        ),
        MeditationContent(
            title: "Ocean Breathing",
            subtitle: "Steady rolling waves",
            description: "Ride the rhythm of the sea for a calming reset.",
            durationMinutes: 8,
            soundscape: .ocean
        ),
        MeditationContent(
            title: "Rainfall Calm",
            subtitle: "Quiet focus",
            description: "Soft rain ambience for deep focus or reflection.",
            durationMinutes: 6,
            soundscape: .rain
        )
    ]
}
