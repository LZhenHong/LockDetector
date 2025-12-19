# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LockDetector is a Swift Package that detects whether an Apple device's screen is locked or unlocked. It supports macOS 12+, iOS 13+, and Mac Catalyst 13+.

## Build and Test Commands

```bash
# Build the package
swift build

# Run all tests
swift test

# Run a specific test
swift test --filter LockDetectorTests.testCurrentState
```

## File Structure

```
Sources/LockDetector/
├── LockDetector.swift        # Public types (ScreenState, ObservationToken) and API
├── LockDetector+macOS.swift  # macOS implementation (CGSession, DistributedNotificationCenter)
└── LockDetector+iOS.swift    # iOS/Catalyst implementation (protected data, file protection)
```

## Architecture

### macOS Implementation (`LockDetector+macOS.swift`)
- **Current state**: Uses `CGSessionCopyCurrentDictionary()` to read `CGSSessionScreenIsLocked` key
- **State changes**: Uses `DistributedNotificationCenter` to observe `com.apple.screenIsLocked` and `com.apple.screenIsUnlocked` notifications

### iOS/Catalyst Implementation (`LockDetector+iOS.swift`)
- **Main app**: Uses `UIApplication.shared.isProtectedDataAvailable` for direct lock state detection
- **App extension** (non-widget): Uses a file-based approach with `FileProtectionType.complete` - creates a protected file that becomes unreadable when the device is locked
- **Widget extension**: Returns `.unknown` (not supported due to sandbox isolation and timeline-based execution)
- **State changes**: Uses `NotificationCenter` to observe `protectedDataDidBecomeAvailableNotification` and `protectedDataWillBecomeUnavailableNotification`

## Public API

### All Platforms
- `LockDetector.currentState` → returns `.locked`, `.unlocked`, or `.unknown`
- `LockDetector.observeStateChanges(_:)` → observes lock/unlock events, returns `ObservationToken`

### iOS Only
- `LockDetector.initialize()` → creates the protected file (call early in app lifecycle for extension support)
- `LockDetector.isAppExtension` → detects if running in an app extension context
- `LockDetector.isWidgetExtension` → detects if running in a Widget Extension (returns `.unknown` for `currentState`)
- `LockDetector.protectedFilePath` → path to the protected file used for extension detection

## Platform Notes

- **macOS**: `currentState` is synchronous (no `@MainActor`); uses Core Graphics session dictionary
- **iOS/Catalyst**: `currentState` requires `@MainActor`; App Extensions must call `initialize()` first
- **Widget Extension**: Not supported - `currentState` returns `.unknown` due to sandbox isolation, no `UIApplication.shared` access, timeline-based execution, and Lock Screen paradox (widgets only display when locked)

## Testing

The test suite includes 14 tests across 5 test classes:

| Test Class | Tests | Description |
|------------|-------|-------------|
| `ScreenStateTests` | 4 | Enum cases, equality, Sendable conformance |
| `ObservationTokenTests` | 4 | Creation, invalidation, multiple observers, deinit |
| `CurrentStateTests` | 2 | Valid values, unlocked device detection |
| `MacOSLockDetectorTests` | 2 | GUI session tests (macOS only) |
| `IOSLockDetectorTests` | 8 | Extension detection, widget detection, protected file (iOS only) |

Run specific test classes:
```bash
swift test --filter ScreenStateTests
swift test --filter ObservationTokenTests
```

## Concurrency

- `ScreenState` conforms to `Sendable` for safe cross-actor usage
- `ObservationToken` is `@unchecked Sendable` (internal synchronization via notification center)
- Handler closures are marked `@Sendable`
- iOS `currentState` requires `@MainActor` due to `UIApplication.shared` access

## Implementation Notes

### Constants
Magic strings are extracted to private enums for maintainability:
- `Notifications` enum: macOS notification names
- `SessionKeys` enum: CGSession dictionary keys

### ObservationToken Design
Uses closure-based `removeObserver` to avoid conditional compilation in `invalidate()`:
```swift
ObservationToken(
    observers: [...],
    removeObserver: { center.removeObserver($0) }
)
```
