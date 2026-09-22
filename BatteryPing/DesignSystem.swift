//
//  DesignSystem.swift
//  BatteryPing
//

import SwiftUI

enum AppTheme {
    static let ink = Color(red: 0.04, green: 0.05, blue: 0.08)
    static let inkSoft = Color(red: 0.09, green: 0.11, blue: 0.16)
    static let mint = Color(red: 0.35, green: 0.98, blue: 0.78)
    static let sky = Color(red: 0.45, green: 0.72, blue: 1.0)
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

struct AmbientBackground: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let t = Float(timeline.date.timeIntervalSinceReferenceDate)
            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    [0, 0], [0.5, 0], [1, 0],
                    [0, 0.5], [0.5 + 0.08 * sin(t / 6), 0.42], [1, 0.5],
                    [0, 1], [0.5, 1], [1, 1]
                ],
                colors: [
                    AppTheme.ink,
                    Color(red: 0.07, green: 0.16, blue: 0.18),
                    AppTheme.ink,
                    Color(red: 0.08, green: 0.10, blue: 0.22),
                    Color(red: 0.12, green: 0.28, blue: 0.26),
                    Color(red: 0.06, green: 0.12, blue: 0.24),
                    AppTheme.inkSoft,
                    AppTheme.ink,
                    Color(red: 0.05, green: 0.08, blue: 0.14)
                ]
            )
        }
        .ignoresSafeArea()
        .overlay {
            LinearGradient(
                colors: [Color.black.opacity(0.15), Color.black.opacity(0.45)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
}

struct GlassCard<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.28), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
    }
}

struct BatteryHalo: View {
    var percentage: Int
    var isCharging: Bool
    var label: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.08), lineWidth: 16)

            Circle()
                .trim(from: 0, to: CGFloat(percentage) / 100)
                .stroke(
                    AngularGradient(
                        colors: [
                            BatteryTint.from(percentage: percentage).color,
                            BatteryTint.from(percentage: percentage).color.opacity(0.35),
                            BatteryTint.from(percentage: percentage).color
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: BatteryTint.from(percentage: percentage).color.opacity(0.45), radius: 16)

            VStack(spacing: 2) {
                if isCharging {
                    Image(systemName: "bolt.fill")
                        .font(AppTheme.label(16, weight: .bold))
                        .foregroundStyle(AppTheme.mint)
                }
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(percentage)")
                        .font(AppTheme.display(64))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                    Text("%")
                        .font(AppTheme.display(26, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Text(label.uppercased())
                    .font(AppTheme.label(11, weight: .semibold))
                    .tracking(2.6)
                    .foregroundStyle(.white.opacity(0.48))
            }
        }
        .frame(width: 220, height: 220)
    }
}

struct DeviceRowCard: View {
    var device: BatteryDevice

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(device.tint.color.opacity(0.16))
                    .frame(width: 48, height: 48)
                Image(systemName: device.symbolName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(device.tint.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(AppTheme.label(16, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(device.isCharging ? "Charging" : "Connected")
                    .font(AppTheme.label(12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.45))
            }

            Spacer()

            Text("\(device.percentage)%")
                .font(AppTheme.display(22, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(device.tint.color)
        }
    }
}
