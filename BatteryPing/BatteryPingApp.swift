//
//  BatteryPingApp.swift
//  BatteryPing
//

import SwiftUI
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    let provider = DeviceBatteryProvider()
    private(set) lazy var connectivity = ConnectivityManager(provider: provider)

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        _ = connectivity
        return true
    }
}

@main
struct BatteryPingApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appDelegate.connectivity)
        }
    }
}
