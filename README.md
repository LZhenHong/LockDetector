# LockDetector

A Swift Package to detect whether an Apple device's screen is locked or unlocked.

## Features

- Detect current lock state (`.locked`, `.unlocked`, `.unknown`)
- Observe lock/unlock state changes in real-time
- Cross-platform support: macOS, iOS, Mac Catalyst
- App Extension support on iOS
- Swift Concurrency ready (`Sendable` conformance)

## Requirements

- macOS 12.0+
- iOS 13.0+
- Mac Catalyst 13.0+
- Swift 5.10+

## Installation

### Swift Package Manager

Add the following to your `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/LZhenHong/LockDetector.git", branch: "main")
]
```

Or in Xcode: File → Add Package Dependencies → Enter the repository URL.

## Usage

### Get Current State

```swift
import LockDetector

// macOS (synchronous)
let state = LockDetector.currentState

// iOS (requires @MainActor)
@MainActor
func checkLockState() {
  let state = LockDetector.currentState
  switch state {
  case .locked:
    print("Device is locked")
  case .unlocked:
    print("Device is unlocked")
  case .unknown:
    print("Unable to determine lock state")
  }
}
```

### Observe State Changes

```swift
import LockDetector

// Store the token to keep observing
let token = LockDetector.observeStateChanges { state in
  print("Screen is now \(state)")
}

// Stop observing when done
token.invalidate()

// Or let the token deinit to auto-invalidate
```

### iOS App Extensions

For App Extensions on iOS (Today Extension, Share Extension, etc.), call `initialize()` early in your extension's lifecycle:

```swift
import LockDetector

// In your extension's entry point
LockDetector.initialize()

// Then check state as needed
@MainActor
func checkState() {
  let state = LockDetector.currentState
}
```

### Widget Extension Limitation

> **⚠️ Widget Extensions are not supported.** `currentState` returns `.unknown` when called from a Widget Extension.

This limitation exists due to fundamental technical constraints:

| Constraint | Description |
|------------|-------------|
| **Sandbox isolation** | Widget Extensions run in a separate container from the main app |
| **No UIApplication** | `UIApplication.shared` is unavailable in Widget Extensions |
| **Timeline-based** | Widgets update at system-determined intervals, not real-time |
| **Lock Screen paradox** | Lock Screen widgets only display when device is locked |

Use `isWidgetExtension` to detect if running in a Widget Extension:

```swift
if LockDetector.isWidgetExtension {
  // Handle widget context - lock detection not available
}
```

## How It Works

### macOS

- **Current state**: Uses `CGSessionCopyCurrentDictionary()` to read the `CGSSessionScreenIsLocked` key
- **State changes**: Observes `com.apple.screenIsLocked` and `com.apple.screenIsUnlocked` via `DistributedNotificationCenter`

### iOS / Mac Catalyst

- **Main app**: Uses `UIApplication.shared.isProtectedDataAvailable`
- **App Extension**: Creates a file with `FileProtectionType.complete` that becomes unreadable when locked
- **State changes**: Observes `protectedDataDidBecomeAvailableNotification` and `protectedDataWillBecomeUnavailableNotification`

## API Reference

### `LockDetector.ScreenState`

```swift
public enum ScreenState: Sendable {
  case unknown   // Unable to determine state
  case locked    // Device is locked
  case unlocked  // Device is unlocked
}
```

### `LockDetector.currentState`

Returns the current lock state.
- **macOS**: Synchronous property
- **iOS/Catalyst**: Requires `@MainActor`

### `LockDetector.observeStateChanges(_:)`

```swift
@discardableResult
public static func observeStateChanges(
  _ handler: @escaping @Sendable (ScreenState) -> Void
) -> ObservationToken
```

Observes lock state changes. Returns an `ObservationToken` to manage the observation lifecycle.

### `LockDetector.ObservationToken`

```swift
public final class ObservationToken: @unchecked Sendable {
  public func invalidate()  // Stop observing
}
```

### iOS-Only APIs

```swift
// Initialize protected file for App Extension support
public static func initialize()

// Check if running in an App Extension
public static var isAppExtension: Bool

// Check if running in a Widget Extension (returns .unknown for currentState)
public static var isWidgetExtension: Bool

// Path to the protected file
public static var protectedFilePath: String
```

## License

MIT License
