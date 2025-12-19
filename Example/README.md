# LockDetector Example

This Xcode project demonstrates how to use the LockDetector Swift Package.

## Requirements

- Xcode 15.0+
- macOS 12.0+ (for macOS target)
- iOS 15.0+ (for iOS target)

## Getting Started

1. Open `LockDetectorExample.xcodeproj` in Xcode
2. Select either `LockDetectorExample-macOS` or `LockDetectorExample-iOS` scheme
3. Build and run

## Features Demonstrated

### Current State Detection

```swift
let state = LockDetector.currentState
// Returns: .locked, .unlocked, or .unknown
```

### State Change Observation

```swift
let token = LockDetector.observeStateChanges { state in
  print("Screen is now \(state)")
}

// To stop observing:
token.invalidate()
```

### iOS-Specific Initialization

```swift
// Call early in app lifecycle for App Extension support
LockDetector.initialize()
```

### Widget Extension Detection

```swift
// Check if running in a Widget Extension
if LockDetector.isWidgetExtension {
  // Lock detection not available in Widget Extensions
  // currentState will return .unknown
}
```

> **Note:** Widget Extensions are not supported. `currentState` returns `.unknown` when called from a Widget Extension due to sandbox isolation, no `UIApplication.shared` access, timeline-based execution, and the Lock Screen paradox (Lock Screen widgets only display when the device is locked).

## Testing

### macOS
- Build and run the macOS target
- Press Ctrl+Cmd+Q to lock your Mac
- Observe the state change in the app

### iOS
- Build and run on a real device (simulator has limited lock detection)
- Press the power button to lock/unlock
- Observe the state changes in the app

## Project Structure

```
Example/
├── macOS/
│   ├── LockDetectorExampleMacApp.swift  # macOS app entry point
│   ├── ContentViewMac.swift              # macOS UI
│   └── LockDetectorExample_macOS.entitlements
├── iOS/
│   ├── LockDetectorExampleiOSApp.swift   # iOS app entry point
│   └── ContentViewiOS.swift              # iOS UI
└── Shared/
    └── Assets.xcassets                    # Shared assets
```
