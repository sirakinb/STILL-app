//
//  HapticProvider.swift
//  Still App
//
//  Abstracts haptic feedback so we can disable or swap implementations easily.
//

import Foundation

protocol HapticProviding {
    func prepare()
    func pulse()
}

struct NoopHapticProvider: HapticProviding {
    func prepare() {}
    func pulse() {}
}

#if canImport(UIKit)
import UIKit

final class DefaultHapticProvider: HapticProviding {
    private let generator = UIImpactFeedbackGenerator(style: .soft)

    func prepare() {
        generator.prepare()
    }

    func pulse() {
        generator.impactOccurred()
    }
}
#else
final class DefaultHapticProvider: HapticProviding {
    func prepare() {}
    func pulse() {}
}
#endif
