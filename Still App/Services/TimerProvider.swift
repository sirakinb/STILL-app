//
//  TimerProvider.swift
//  Still App
//
//  Provides testable timer publishers for view models.
//

import Foundation
import Combine

protocol TimerProviding {
    func publisher(every interval: TimeInterval) -> AnyPublisher<Date, Never>
}

struct DefaultTimerProvider: TimerProviding {
    func publisher(every interval: TimeInterval) -> AnyPublisher<Date, Never> {
        Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .eraseToAnyPublisher()
    }
}
