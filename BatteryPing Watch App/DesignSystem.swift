//
//  DesignSystem.swift
//  BatteryPing Watch App
//

import SwiftUI

enum AppTheme {
    static let mint = Color(red: 0.35, green: 0.98, blue: 0.78)
    static let amber = Color(red: 1.0, green: 0.78, blue: 0.32)
    static let coral = Color(red: 1.0, green: 0.42, blue: 0.45)

    static func color(for tint: BatteryTint) -> Color {
        switch tint {
        case .high: mint
        case .medium: amber
        case .low: coral
        }
    }

    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func label(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

extension BatteryTint {
    var color: Color { AppTheme.color(for: self) }
}
