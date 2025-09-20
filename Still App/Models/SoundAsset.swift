//
//  SoundAsset.swift
//  Still App
//
//  Defines filenames for bundled audio resources so views
//  and view models can reference them safely.
//

import Foundation

enum SoundAsset: String, CaseIterable {
    case startChime   = "start_chime.caf"
    case endChime     = "end_chime.caf"
    case rainLoop     = "rain_loop.caf"
    case oceanLoop    = "ocean_loop.caf"
    case meditationA  = "meditation_A.mp3"
    case meditationB  = "meditation_B.mp3"
}
