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

## Architecture

The library uses conditional compilation (`#if canImport`) to provide platform-specific implementations:

### macOS Implementation
- **Current state**: Uses `CGSessionCopyCurrentDictionary()` to read `CGSSessionScreenIsLocked` key
- **State changes**: Uses `DistributedNotificationCenter` to observe `com.apple.screenIsLocked` and `com.apple.screenIsUnlocked` notifications

### iOS/Catalyst Implementation
- **Main app**: Uses `UIApplication.shared.isProtectedDataAvailable` for direct lock state detection
- **App extension**: Uses a file-based approach with `FileProtectionType.complete` - creates a protected file that becomes unreadable when the device is locked
- **State changes**: Uses `NotificationCenter` to observe `protectedDataDidBecomeAvailableNotification` and `protectedDataWillBecomeUnavailableNotification`

## Public API

### All Platforms
- `LockDetector.currentState` → returns `.locked`, `.unlocked`, or `.unknown`
- `LockDetector.observeStateChanges(_:)` → observes lock/unlock events, returns `ObservationToken`

### iOS Only
- `LockDetector.initialize()` → creates the protected file (call early in app lifecycle for extension support)
- `LockDetector.isAppExtension` → detects if running in an app extension context
- `LockDetector.protectedFilePath` → path to the protected file used for extension detection

## Platform Notes

- **macOS**: `currentState` is synchronous (no `@MainActor`); uses Core Graphics session dictionary
- **iOS/Catalyst**: `currentState` requires `@MainActor`; App Extensions must call `initialize()` first
