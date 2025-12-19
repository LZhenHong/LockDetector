# LockDetector Example

This Xcode project demonstrates how to use the LockDetector Swift Package in various contexts, including main apps and App Extensions.

## Requirements

- Xcode 15.0+
- macOS 12.0+ (for macOS target)
- iOS 17.0+ (for iOS target and extensions)

## Getting Started

1. Open `LockDetectorExample.xcodeproj` in Xcode
2. Select a scheme:
   - `LockDetectorExample-macOS` - macOS app demo
   - `LockDetectorExample-iOS` - iOS app demo (includes widget extension)
   - `LockWidgetExtension` - Widget Extension demo (shows limitations)
3. Build and run

## Targets

### Main Apps

| Target | Platform | Description |
|--------|----------|-------------|
| `LockDetectorExample-macOS` | macOS 12+ | Demonstrates CGSession-based lock detection |
| `LockDetectorExample-iOS` | iOS 17+ | Demonstrates protected data-based lock detection |

### App Extensions

| Target | Type | Lock Detection |
|--------|------|----------------|
| `LockWidgetExtension` | Widget Extension | ❌ Not Supported (returns `.unknown`) |

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

### Extension Detection

```swift
// Check if running in an App Extension
if LockDetector.isAppExtension {
  print("Running in an App Extension")
}

// Check if running in a Widget Extension
if LockDetector.isWidgetExtension {
  // Lock detection not available
  // currentState will return .unknown
}
```

## Widget Extension Example

The Widget Extension demonstrates the limitations of lock detection in WidgetKit:

```swift
// In LockWidget.swift
struct LockWidgetProvider: TimelineProvider {
  func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    // Always returns .unknown in Widget Extensions
    let state = LockDetector.currentState
    print("State: \(state)") // Prints: unknown
  }
}
```

**Why Widget Extensions Don't Support Lock Detection:**

1. **Sandbox Isolation**: Widget Extensions run in a separate container from the main app
2. **No UIApplication Access**: Cannot use `isProtectedDataAvailable`
3. **Timeline-Based Execution**: Widgets update at system-determined intervals, not in real-time
4. **Lock Screen Paradox**: Lock Screen widgets only display when the device is locked

## Testing

### macOS
- Build and run the macOS target
- Press Ctrl+Cmd+Q to lock your Mac
- Observe the state change in the app

### iOS Main App
- Build and run on a **real device** (simulator has limited lock detection)
- Press the power button to lock/unlock
- Observe the state changes in the app

### Widget Extension
1. Run the iOS app
2. Add the "Lock State" widget to your home screen
3. Observe that it always shows "Not Supported"

## Project Structure

```
Example/
├── LockDetectorExample.xcodeproj/
│   └── xcshareddata/xcschemes/
│       ├── LockDetectorExample-iOS.xcscheme
│       ├── LockDetectorExample-macOS.xcscheme
│       └── LockWidgetExtension.xcscheme
├── macOS/
│   ├── LockDetectorExampleMacApp.swift
│   ├── ContentViewMac.swift
│   └── LockDetectorExample_macOS.entitlements
├── iOS/
│   ├── LockDetectorExampleiOSApp.swift
│   └── ContentViewiOS.swift
├── Shared/
│   ├── LockStateViewModel.swift
│   ├── LockStateComponents.swift
│   └── Assets.xcassets/
└── Extensions/
    └── LockWidget/
        ├── LockWidget.swift
        ├── Info.plist
        └── Assets.xcassets/
```

## Extension Support Matrix

| Feature | Main App | Widget Extension |
|---------|----------|------------------|
| `currentState` | ✅ Works | ❌ Returns `.unknown` |
| `observeStateChanges` | ✅ Works | ⚠️ Limited* |
| `isAppExtension` | `false` | `true` |
| `isWidgetExtension` | `false` | `true` |
| `initialize()` required | ✅ Yes | N/A |

\* Notifications may not be delivered reliably in Widget Extensions
