//
//  ConnectivityManager.swift
//  BatteryPing Watch App
//

import Foundation
import WatchConnectivity
import Observation

@Observable
final class ConnectivityManager: NSObject, WCSessionDelegate {
    var devices: [BatteryDevice] = []
    var isRefreshing = false
    var statusMessage = "Waiting for iPhone"

    private var shouldRequestAfterActivation = false

    override init() {
        super.init()

        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func requestDevices() {
        let session = WCSession.default
        guard session.activationState == .activated else {
            shouldRequestAfterActivation = true
            statusMessage = "Connecting…"
            return
        }

        isRefreshing = true
        statusMessage = "Fetching…"
        session.sendMessage(
            [BatteryMessage.requestKey: BatteryMessage.devicesRequest],
            replyHandler: { [weak self] reply in
                let raw = reply[BatteryMessage.devicesKey] as? [[String: Any]] ?? []
                let devices = raw.compactMap(BatteryDevice.init(dictionary:))
                Task { @MainActor in
                    self?.isRefreshing = false
                    self?.devices = devices
                    self?.statusMessage = devices.isEmpty ? "No devices found" : "Live from iPhone"
                }
            },
            errorHandler: { [weak self] error in
                Task { @MainActor in
                    self?.isRefreshing = false
                    self?.statusMessage = error.localizedDescription
                }
            }
        )
    }

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {
        Task { @MainActor in
            if shouldRequestAfterActivation {
                shouldRequestAfterActivation = false
                requestDevices()
            }
        }
    }

#if !os(watchOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
#endif
}
