//
//  AppColors.swift
//  Still App
//
//  Created by Akinyemi Bajulaiye on 9/20/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension Color {
#if canImport(UIKit)
    static let stillBackground = dynamic(light: UIColor(red: 0.94, green: 0.95, blue: 0.96, alpha: 1.0),
                                         dark: UIColor(red: 0.08, green: 0.10, blue: 0.14, alpha: 1.0))
    static let stillDeepBlue   = dynamic(light: UIColor(red: 0.18, green: 0.29, blue: 0.47, alpha: 1.0),
                                         dark: UIColor(red: 0.36, green: 0.55, blue: 0.78, alpha: 1.0))
    static let stillSoftBeige  = dynamic(light: UIColor(red: 0.93, green: 0.88, blue: 0.80, alpha: 1.0),
                                         dark: UIColor(red: 0.53, green: 0.47, blue: 0.40, alpha: 1.0))
    static let stillAccent     = dynamic(light: UIColor(red: 0.29, green: 0.41, blue: 0.59, alpha: 1.0),
                                         dark: UIColor(red: 0.47, green: 0.64, blue: 0.82, alpha: 1.0))
    static let stillPrimaryText   = dynamic(light: UIColor(red: 0.11, green: 0.16, blue: 0.22, alpha: 1.0),
                                            dark: UIColor(red: 0.89, green: 0.93, blue: 0.97, alpha: 1.0))
    static let stillSecondaryText = dynamic(light: UIColor(red: 0.36, green: 0.39, blue: 0.43, alpha: 1.0),
                                            dark: UIColor(red: 0.73, green: 0.79, blue: 0.84, alpha: 1.0))
    static let stillOverlay    = dynamic(light: UIColor(red: 0.87, green: 0.90, blue: 0.93, alpha: 1.0),
                                         dark: UIColor(red: 0.11, green: 0.14, blue: 0.19, alpha: 1.0))
#elseif canImport(AppKit)
    static let stillBackground = dynamic(light: NSColor(red: 0.94, green: 0.95, blue: 0.96, alpha: 1.0),
                                         dark: NSColor(red: 0.08, green: 0.10, blue: 0.14, alpha: 1.0))
    static let stillDeepBlue   = dynamic(light: NSColor(red: 0.18, green: 0.29, blue: 0.47, alpha: 1.0),
                                         dark: NSColor(red: 0.36, green: 0.55, blue: 0.78, alpha: 1.0))
    static let stillSoftBeige  = dynamic(light: NSColor(red: 0.93, green: 0.88, blue: 0.80, alpha: 1.0),
                                         dark: NSColor(red: 0.53, green: 0.47, blue: 0.40, alpha: 1.0))
    static let stillAccent     = dynamic(light: NSColor(red: 0.29, green: 0.41, blue: 0.59, alpha: 1.0),
                                         dark: NSColor(red: 0.47, green: 0.64, blue: 0.82, alpha: 1.0))
    static let stillPrimaryText   = dynamic(light: NSColor(red: 0.11, green: 0.16, blue: 0.22, alpha: 1.0),
                                            dark: NSColor(red: 0.89, green: 0.93, blue: 0.97, alpha: 1.0))
    static let stillSecondaryText = dynamic(light: NSColor(red: 0.36, green: 0.39, blue: 0.43, alpha: 1.0),
                                            dark: NSColor(red: 0.73, green: 0.79, blue: 0.84, alpha: 1.0))
    static let stillOverlay    = dynamic(light: NSColor(red: 0.87, green: 0.90, blue: 0.93, alpha: 1.0),
                                         dark: NSColor(red: 0.11, green: 0.14, blue: 0.19, alpha: 1.0))
#endif
}

private extension Color {
#if canImport(UIKit)
    static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
#elseif canImport(AppKit)
    static func dynamic(light: NSColor, dark: NSColor) -> Color {
        let dynamic = NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        }
        return Color(dynamic ?? light)
    }
#endif
}
