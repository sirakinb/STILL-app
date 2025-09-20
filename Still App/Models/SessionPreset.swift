//
//  SessionPreset.swift
//  Still App
//
//  Encapsulates the duration options offered on the home screen.
//

import Foundation

struct SessionPreset: Identifiable, Equatable {
    enum Kind: Hashable {
        case fixed(minutes: Int)
        case custom
    }

    let kind: Kind

    var id: String {
        switch kind {
        case .fixed(let minutes):
            return "fixed-\(minutes)"
        case .custom:
            return "custom"
        }
    }

    var displayName: String {
        switch kind {
        case .fixed(let minutes):
            return "\(minutes) min"
        case .custom:
            return "Custom"
        }
    }

    var minutes: Int? {
        switch kind {
        case .fixed(let minutes):
            return minutes
        case .custom:
            return nil
        }
    }
}
