//
//  ContentView.swift
//  BatteryPing Watch App
//

import SwiftUI

struct ContentView: View {
    @Environment(ConnectivityManager.self) private var connectivity
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.12, blue: 0.14),
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        statusChip

                        if !connectivity.devices.isEmpty {
                            watchSummary
                        }

                        if connectivity.devices.isEmpty {
                            emptyState
                        } else {
                            ForEach(connectivity.devices) { device in
                                deviceCard(device)
                            }
                        }

                        Button {
                            connectivity.requestDevices()
                        } label: {
                            Label(connectivity.isRefreshing ? "Fetching" : "Refresh snapshot", systemImage: "arrow.clockwise")
                                .font(AppTheme.label(15, weight: .bold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.mint)
                        .foregroundStyle(.black)
                        .disabled(connectivity.isRefreshing)
                    }
                    .padding(.horizontal, 6)
                    .padding(.bottom, 8)
                }
            }
            .navigationTitle("Power")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { connectivity.requestDevices() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                connectivity.requestDevices()
            }
        }
    }

    private var statusChip: some View {
        Text(connectivity.statusMessage.uppercased())
            .font(AppTheme.label(10, weight: .bold))
            .tracking(1.2)
            .foregroundStyle(AppTheme.mint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AppTheme.mint.opacity(0.12), in: Capsule())
    }

    private var watchSummary: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("YOUR DEVICES")
                    .font(AppTheme.label(9, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(.white.opacity(0.42))
                Text("\(connectivity.devices.count) connected")
                    .font(AppTheme.display(18, weight: .bold))
            }
            Spacer()
            Image(systemName: "bolt.horizontal.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(AppTheme.mint)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("No snapshot yet")
                .font(AppTheme.display(20, weight: .bold))
            Text("Refresh to pull your iPhone, AirPods, case, and external headphones. The iPhone app can stay closed.")
                .font(AppTheme.label(13, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.vertical, 8)
    }

    private func deviceCard(_ device: BatteryDevice) -> some View {
        HStack(spacing: 10) {
            Image(systemName: device.symbolName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(device.tint.color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 1) {
                Text(device.name)
                    .font(AppTheme.label(13, weight: .semibold))
                    .lineLimit(1)
                Text(!device.isAvailable ? "Battery unavailable" : (device.isCharging ? "Charging" : "Connected"))
                    .font(AppTheme.label(11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.45))
            }

            Spacer(minLength: 4)

            Text(device.isAvailable ? "\(device.percentage)%" : "—")
                .font(AppTheme.display(22, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(device.tint.color)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    ContentView()
        .environment(ConnectivityManager())
}
