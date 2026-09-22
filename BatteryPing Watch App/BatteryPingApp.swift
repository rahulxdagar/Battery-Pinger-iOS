//
//  BatteryPingApp.swift
//  BatteryPing Watch App
//
//  Created by Rahul Dagar on 2026-09-13.
//

import SwiftUI

@main
struct BatteryPing_Watch_AppApp: App {
    @State private var connectivity = ConnectivityManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(connectivity)
        }
    }
}
