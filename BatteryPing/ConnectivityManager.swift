//
//  ConnectivityManager.swift
//  BatteryPing
//

import Foundation
import WatchConnectivity
import Observation

@Observable
final class ConnectivityManager: NSObject, WCSessionDelegate {
    let provider: DeviceBatteryProvider

    init(provider: DeviceBatteryProvider) {
        self.provider = provider
        super.init()

        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    private func devicesPayload() -> [String: Any] {
        provider.pollConnectedBluetoothDevices()
        let devices = provider.snapshot()
        provider.devices = devices
        return [
            BatteryMessage.devicesKey: devices.map(\.dictionary)
        ]
    }

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {}

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        guard message[BatteryMessage.requestKey] as? String == BatteryMessage.devicesRequest else {
            replyHandler([:])
            return
        }

        let respond = {
            replyHandler(self.devicesPayload())
        }

        if Thread.isMainThread {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: respond)
        } else {
            DispatchQueue.main.async {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: respond)
            }
        }
    }
}
