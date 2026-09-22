//
//  DeviceBatteryProvider.swift
//  BatteryPing
//

import CoreBluetooth
import Darwin
import Foundation
import Observation
import UIKit

@Observable
final class DeviceBatteryProvider: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var devices: [BatteryDevice] = []

    private var central: CBCentralManager?
    private var peripherals: [UUID: CBPeripheral] = [:]
    private var bleDevices: [String: BatteryDevice] = [:]
    private let batteryServiceID = CBUUID(string: "180F")
    private let batteryLevelID = CBUUID(string: "2A19")

    override init() {
        super.init()
        loadBatteryCenterIfNeeded()

        #if !targetEnvironment(simulator)
        UIDevice.current.isBatteryMonitoringEnabled = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refresh),
            name: UIDevice.batteryLevelDidChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refresh),
            name: UIDevice.batteryStateDidChangeNotification,
            object: nil
        )
        central = CBCentralManager(
            delegate: self,
            queue: .main,
            options: [CBCentralManagerOptionShowPowerAlertKey: false]
        )
        #endif

        refresh()
    }

    @objc func refresh() {
        devices = snapshot()
    }

    func snapshot() -> [BatteryDevice] {
        #if targetEnvironment(simulator)
        return [iPhoneDevice()]
        #else
        var merged: [String: BatteryDevice] = [:]
        let iPhone = iPhoneDevice()
        merged[iPhone.id] = iPhone

        for device in batteryCenterDevices() where device.kind != .iPhone {
            merged[device.id] = device
        }
        for device in bleDevices.values {
            if merged[device.id] == nil {
                merged[device.id] = device
            }
        }

        return merged.values.sorted { lhs, rhs in
            if lhs.kind == .iPhone { return true }
            if rhs.kind == .iPhone { return false }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
        #endif
    }

    private func iPhoneDevice() -> BatteryDevice {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = UIDevice.current.batteryLevel
        let hasBatteryReading = level >= 0
        let percentage = hasBatteryReading ? Int((level * 100).rounded()) : 0
        let charging: Bool = {
            switch UIDevice.current.batteryState {
            case .charging, .full: return true
            default: return false
            }
        }()

        return BatteryDevice(
            id: "iphone",
            name: UIDevice.current.name,
            percentage: percentage,
            isAvailable: hasBatteryReading,
            isCharging: charging,
            kind: .iPhone
        )
    }

    private func loadBatteryCenterIfNeeded() {
        _ = dlopen(
            "/System/Library/PrivateFrameworks/BatteryCenter.framework/BatteryCenter",
            RTLD_NOW
        )
    }

    private func batteryCenterDevices() -> [BatteryDevice] {
        guard
            let controllerClass = NSClassFromString("BCBatteryDeviceController") as? NSObject.Type
        else { return [] }

        let sharedSelector = NSSelectorFromString("sharedInstance")
        guard controllerClass.responds(to: sharedSelector),
              let controller = controllerClass.perform(sharedSelector)?.takeUnretainedValue() as? NSObject
        else { return [] }

        let devicesSelector = NSSelectorFromString("connectedDevices")
        guard controller.responds(to: devicesSelector),
              let rawDevices = controller.perform(devicesSelector)?.takeUnretainedValue() as? [NSObject]
        else { return [] }

        return rawDevices.compactMap { object in
            if let connected = (object.value(forKey: "connected") as? Bool)
                ?? (object.value(forKey: "isConnected") as? Bool), !connected {
                return nil
            }

            let isInternal = (object.value(forKey: "internal") as? Bool)
                ?? (object.value(forKey: "isInternal") as? Bool)
                ?? false
            if isInternal { return nil }

            let name = (object.value(forKey: "name") as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let name, !name.isEmpty else { return nil }

            let groupName = object.value(forKey: "groupName") as? String
            let identifier = (object.value(forKey: "identifier") as? String)
                ?? (object.value(forKey: "matchIdentifier") as? String)
                ?? name
            let percent = (object.value(forKey: "percentCharge") as? Int)
                ?? (object.value(forKey: "percentCharge") as? NSNumber)?.intValue
            guard let percent, (0...100).contains(percent) else { return nil }

            let charging = (object.value(forKey: "charging") as? Bool)
                ?? (object.value(forKey: "isCharging") as? Bool)
                ?? false

            let displayName: String = {
                if let groupName, !groupName.isEmpty, groupName.caseInsensitiveCompare(name) != .orderedSame {
                    return "\(groupName) · \(name)"
                }
                return name
            }()

            return BatteryDevice(
                id: identifier,
                name: displayName,
                percentage: percent,
                isCharging: charging,
                kind: BatteryDevice.inferKind(name: name, groupName: groupName)
            )
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else { return }
        pollConnectedBluetoothDevices()
    }

    func pollConnectedBluetoothDevices() {
        guard let central, central.state == .poweredOn else { return }

        let connected = central.retrieveConnectedPeripherals(withServices: [batteryServiceID])
        let connectedIDs = Set(connected.map(\.identifier.uuidString))
        bleDevices = bleDevices.filter { connectedIDs.contains($0.key) }
        for peripheral in connected {
            peripherals[peripheral.identifier] = peripheral
            peripheral.delegate = self
            if peripheral.state == .connected {
                peripheral.discoverServices([batteryServiceID])
            } else {
                central.connect(peripheral)
            }
        }
        refresh()
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices([batteryServiceID])
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        peripheral.services?
            .filter { $0.uuid == batteryServiceID }
            .forEach { peripheral.discoverCharacteristics([batteryLevelID], for: $0) }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        service.characteristics?
            .filter { $0.uuid == batteryLevelID }
            .forEach {
                peripheral.readValue(for: $0)
                peripheral.setNotifyValue(true, for: $0)
            }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic.uuid == batteryLevelID, let byte = characteristic.value?.first else { return }
        let name = peripheral.name ?? "Bluetooth Headphones"
        let device = BatteryDevice(
            id: peripheral.identifier.uuidString,
            name: name,
            percentage: Int(byte),
            isCharging: false,
            kind: BatteryDevice.inferKind(name: name)
        )
        bleDevices[device.id] = device
        refresh()
    }
}
