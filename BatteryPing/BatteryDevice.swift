//
//  BatteryDevice.swift
//  BatteryPing
//

import Foundation

struct BatteryDevice: Identifiable, Hashable, Sendable {
    enum Kind: String, Sendable {
        case iPhone
        case airPods
        case airPodsCase
        case headphones
        case other
    }

    let id: String
    let name: String
    let percentage: Int
    let isAvailable: Bool
    let isCharging: Bool
    let kind: Kind

    var symbolName: String {
        switch kind {
        case .iPhone: "iphone"
        case .airPods: "airpods.pro"
        case .airPodsCase: "airpods.chargingcase"
        case .headphones: "headphones"
        case .other: "battery.100percent"
        }
    }

    var tint: BatteryTint {
        BatteryTint.from(percentage: percentage)
    }

    var dictionary: [String: Any] {
        [
            "id": id,
            "name": name,
            "percentage": percentage,
            "isAvailable": isAvailable,
            "isCharging": isCharging,
            "kind": kind.rawValue
        ]
    }

    init(
        id: String,
        name: String,
        percentage: Int,
        isAvailable: Bool = true,
        isCharging: Bool,
        kind: Kind
    ) {
        self.id = id
        self.name = name
        self.percentage = min(100, max(0, percentage))
        self.isAvailable = isAvailable
        self.isCharging = isCharging
        self.kind = kind
    }

    init?(dictionary: [String: Any]) {
        guard
            let id = dictionary["id"] as? String,
            let name = dictionary["name"] as? String,
            let percentage = dictionary["percentage"] as? Int,
            let kindRaw = dictionary["kind"] as? String,
            let kind = Kind(rawValue: kindRaw)
        else { return nil }

        self.init(
            id: id,
            name: name,
            percentage: percentage,
            isAvailable: dictionary["isAvailable"] as? Bool ?? true,
            isCharging: dictionary["isCharging"] as? Bool ?? false,
            kind: kind
        )
    }

    static func inferKind(name: String, groupName: String? = nil) -> Kind {
        let haystack = [name, groupName]
            .compactMap { $0?.lowercased() }
            .joined(separator: " ")

        if haystack.contains("iphone") || haystack.contains("internal battery") {
            return .iPhone
        }
        if haystack.contains("case") {
            return .airPodsCase
        }
        if haystack.contains("airpod") || haystack.contains("earbuds") {
            return .airPods
        }
        if haystack.contains("headphone")
            || haystack.contains("headset")
            || haystack.contains("beats")
            || haystack.contains("wh-") {
            return .headphones
        }
        return .other
    }
}

enum BatteryTint {
    case high, medium, low

    static func from(percentage: Int) -> BatteryTint {
        if percentage >= 50 { return .high }
        if percentage >= 20 { return .medium }
        return .low
    }
}

enum BatteryMessage {
    static let requestKey = "request"
    static let devicesRequest = "deviceBatteries"
    static let devicesKey = "devices"
}
