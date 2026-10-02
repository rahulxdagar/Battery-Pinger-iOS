# BatteryPing

BatteryPing shows the iPhone battery and battery levels reported by connected
Bluetooth accessories on iPhone and Apple Watch.

## Requirements

- Xcode with the iOS 26 and watchOS 26 SDKs
- iPhone running iOS 26 or later
- Apple Watch running watchOS 26 or later for Watch support
- A Bluetooth accessory that exposes the standard Battery Service (UUID 180F)

The app uses public UIKit, CoreBluetooth, SwiftUI, and WatchConnectivity APIs.
Apple-owned accessories may not expose their individual earbud or case levels
to third-party apps, so AirPods readings are not guaranteed by public APIs.

## Run

Open `BatteryPing.xcodeproj` in Xcode, select the `BatteryPing` scheme, choose a
physical iPhone or simulator, and run. Pair a physical Watch with the iPhone to
test WatchConnectivity. Simulators cannot provide real Bluetooth accessory
levels.

## Privacy

BatteryPing reads battery values locally. It does not require an account and
does not send battery data to a server. Bluetooth access is used to read the
standard Battery Service from supported connected accessories.

## Contributing

Create a feature branch and open a pull request into `main`. Changes to the
repository require owner review through `CODEOWNERS` and the protected branch
ruleset.