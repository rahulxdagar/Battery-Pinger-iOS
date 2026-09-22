//
//  ContentView.swift
//  BatteryPing
//

import SwiftUI

struct ContentView: View {
    @Environment(ConnectivityManager.self) private var connectivity

    private var provider: DeviceBatteryProvider { connectivity.provider }
    private var iPhone: BatteryDevice? { provider.devices.first(where: { $0.kind == .iPhone }) }
    private var accessories: [BatteryDevice] { provider.devices.filter { $0.kind != .iPhone } }
    private var accessoryKinds: Set<BatteryDevice.Kind> { Set(accessories.map(\.kind)) }

    var body: some View {
        ZStack {
            AmbientBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    hero
                    accessorySummary
                    accessorySection
                }
                .padding(.horizontal, 22)
                .padding(.top, 16)
                .padding(.bottom, 36)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { provider.refresh() }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("BATTERYPING")
                    .font(AppTheme.label(12, weight: .bold))
                    .tracking(4)
                    .foregroundStyle(AppTheme.mint)
                Text("Power around you")
                    .font(AppTheme.display(34, weight: .bold))
                    .foregroundStyle(.white)
                Text("A live snapshot for your Watch")
                    .font(AppTheme.label(14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.48))
            }
            Spacer()
            Button { provider.refresh() } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppTheme.mint)
                    .frame(width: 42, height: 42)
                    .background(.white.opacity(0.09), in: Circle())
            }
            .accessibilityLabel("Refresh battery levels")
        }
    }

    @ViewBuilder
    private var hero: some View {
        if let iPhone {
            GlassCard(padding: 22) {
                VStack(spacing: 18) {
                    BatteryHalo(
                        percentage: iPhone.percentage,
                        isCharging: iPhone.isCharging,
                        label: iPhone.name
                    )
                    HStack(spacing: 6) {
                        Circle().fill(AppTheme.mint).frame(width: 6, height: 6)
                        Text("Ready whenever Apple Watch asks")
                            .font(AppTheme.label(13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.42))
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var accessorySummary: some View {
        HStack(spacing: 10) {
            summaryItem("headphones", title: "Audio", count: accessories.count)
            summaryItem("wave.3.right", title: "Bluetooth", count: accessoryKinds.isEmpty ? 0 : 1)
            summaryItem("applewatch", title: "Watch", count: 1)
        }
    }

    private func summaryItem(_ symbol: String, title: String, count: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.mint)
            Text("\(count)")
                .font(AppTheme.display(20, weight: .bold))
                .foregroundStyle(.white)
            Text(title.uppercased())
                .font(AppTheme.label(9, weight: .bold))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.42))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var accessorySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Connected accessories")
                    .font(AppTheme.label(13, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
                Text("\(accessories.count) found")
                    .font(AppTheme.label(12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.35))
            }

            if accessories.isEmpty {
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No accessories yet")
                            .font(AppTheme.label(17, weight: .semibold))
                            .foregroundStyle(.white)
                        Text("Connect AirPods, their case, or external headphones. BatteryPing reads them when your Watch asks.")
                            .font(AppTheme.label(14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(accessories) { device in
                        GlassCard(padding: 16) {
                            DeviceRowCard(device: device)
                        }
                    }
                }
            }
        }
    }

}

#Preview {
    let provider = DeviceBatteryProvider()
    ContentView()
        .environment(ConnectivityManager(provider: provider))
}
