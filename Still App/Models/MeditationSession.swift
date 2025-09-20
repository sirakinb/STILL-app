//
//  MeditationSession.swift
//  Still App
//
//  Created by Akinyemi Bajulaiye on 9/20/25.
//

import Foundation

struct MeditationSession: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let duration: TimeInterval
}

extension MeditationSession {
    static let fiveMinuteReset = MeditationSession(title: "5 Minute Reset", duration: 5 * 60)
}
