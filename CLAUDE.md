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

The library uses a single-file design (`Sources/LockDetector/LockDetector.swift`) with a public enum `LockDetector` that provides:

- **Platform abstraction**: Uses conditional compilation (`#if canImport`) to handle AppKit (macOS) vs UIKit (iOS/Catalyst) differences through a unified `Application` typealias.

- **Two detection strategies**:
  1. **Main app**: Uses `Application.shared.isProtectedDataAvailable` for direct lock state detection
  2. **App extension**: Uses a file-based approach with `FileProtectionType.complete` - creates a protected file that becomes unreadable when the device is locked

- **Public API** (all `@MainActor`):
  - `LockDetector.currentState` → returns `.locked`, `.unlocked`, or `.unknown`
  - `LockDetector.initialize()` → creates the protected file (call early in app lifecycle for extension support)
  - `LockDetector.isAppExtension` → detects if running in an app extension context

## Platform Notes

- **macOS**: `FileProtectionType.complete` relies on FileVault; file-based detection may not work as expected
- **App Extensions**: Must call `initialize()` before using `currentState` for reliable detection
