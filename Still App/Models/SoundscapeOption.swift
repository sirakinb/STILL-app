//
//  SoundscapeOption.swift
//  Still App
//
//  Represents the ambient audio beds a user can choose.
//

import Foundation

enum SoundscapeOption: String, CaseIterable, Identifiable, Hashable {
    case none
    case rain
    case ocean
    case meditationA
    case meditationB

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "Silence"
        case .rain: return "Rain"
        case .ocean: return "Ocean"
        case .meditationA: return "Meditation A"
        case .meditationB: return "Meditation B"
        }
    }

    var asset: SoundAsset? {
        switch self {
        case .none: return nil
        case .rain: return .rainLoop
        case .ocean: return .oceanLoop
        case .meditationA: return .meditationA
        case .meditationB: return .meditationB
        }
    }

    var loopsIndefinitely: Bool {
        switch self {
        case .none, .meditationA, .meditationB:
            return false
        case .rain, .ocean:
            return true
        }
    }
}
