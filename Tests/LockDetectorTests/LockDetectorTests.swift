@testable import LockDetector
import XCTest

// MARK: - ScreenState Tests

final class ScreenStateTests: XCTestCase {
  func testAllCases() {
    // Verify all cases exist and are distinct
    let states: [LockDetector.ScreenState] = [.unknown, .locked, .unlocked]
    XCTAssertEqual(states.count, 3)
    XCTAssertEqual(Set(states.map { "\($0)" }).count, 3)
  }

  func testEquality() {
    XCTAssertEqual(LockDetector.ScreenState.locked, .locked)
    XCTAssertEqual(LockDetector.ScreenState.unlocked, .unlocked)
    XCTAssertEqual(LockDetector.ScreenState.unknown, .unknown)
  }

  func testInequality() {
    XCTAssertNotEqual(LockDetector.ScreenState.locked, .unlocked)
    XCTAssertNotEqual(LockDetector.ScreenState.locked, .unknown)
    XCTAssertNotEqual(LockDetector.ScreenState.unlocked, .unknown)
  }

  func testSendableConformance() {
    // ScreenState should be usable across concurrency boundaries
    let state: LockDetector.ScreenState = .unlocked
    Task {
      // This compiles only if ScreenState conforms to Sendable
      _ = state
    }
  }
}

// MARK: - ObservationToken Tests

final class ObservationTokenTests: XCTestCase {
  func testTokenCreation() {
    let token = LockDetector.observeStateChanges { _ in }
    XCTAssertNotNil(token)
    token.invalidate()
  }

  func testInvalidate() {
    let token = LockDetector.observeStateChanges { _ in }

    // First invalidate should succeed
    token.invalidate()

    // Second invalidate should not crash (idempotent)
    token.invalidate()
  }

  func testMultipleObservers() {
    let token1 = LockDetector.observeStateChanges { _ in }
    let token2 = LockDetector.observeStateChanges { _ in }

    XCTAssertNotNil(token1)
    XCTAssertNotNil(token2)

    // Invalidating one should not affect the other
    token1.invalidate()
    token2.invalidate()
  }

  func testTokenDeinit() {
    // Token should auto-invalidate on deinit
    weak var weakToken: LockDetector.ObservationToken?

    autoreleasepool {
      let token = LockDetector.observeStateChanges { _ in }
      weakToken = token
      XCTAssertNotNil(weakToken)
    }

    // After autoreleasepool, token should be deallocated
    XCTAssertNil(weakToken)
  }
}

// MARK: - CurrentState Tests

final class CurrentStateTests: XCTestCase {
  func testCurrentStateReturnsValidValue() {
    let state = LockDetector.currentState
    let validStates: [LockDetector.ScreenState] = [.unknown, .locked, .unlocked]
    XCTAssertTrue(validStates.contains(state))
  }

  func testCurrentStateIsUnlockedOnUnlockedDevice() {
    // When running tests, device should be unlocked
    let state = LockDetector.currentState
    XCTAssertEqual(state, .unlocked)
  }
}

// MARK: - macOS-specific Tests

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
final class MacOSLockDetectorTests: XCTestCase {
  func testCurrentStateNotUnknownInGUISession() {
    // On a GUI session, should not return unknown
    let state = LockDetector.currentState
    XCTAssertNotEqual(state, .unknown)
  }

  func testCurrentStateIsUnlocked() {
    // When running tests interactively, screen should be unlocked
    let state = LockDetector.currentState
    XCTAssertEqual(state, .unlocked)
  }
}
#endif

// MARK: - iOS-specific Tests

#if canImport(UIKit) && !os(macOS)
final class IOSLockDetectorTests: XCTestCase {
  func testIsAppExtension() {
    // Test runner is not an app extension
    XCTAssertFalse(LockDetector.isAppExtension)
  }

  func testProtectedFilePathNotEmpty() {
    XCTAssertFalse(LockDetector.protectedFilePath.isEmpty)
  }

  func testProtectedFilePathFormat() {
    XCTAssertTrue(LockDetector.protectedFilePath.hasSuffix("/protected"))
    XCTAssertTrue(LockDetector.protectedFilePath.contains("Documents"))
  }

  func testInitialize() {
    // Should create protected file
    LockDetector.initialize()
    XCTAssertTrue(FileManager.default.fileExists(atPath: LockDetector.protectedFilePath))
  }

  func testInitializeIdempotent() {
    // Multiple calls should not fail
    LockDetector.initialize()
    LockDetector.initialize()
    XCTAssertTrue(FileManager.default.fileExists(atPath: LockDetector.protectedFilePath))
  }

  @MainActor
  func testCurrentStateOnMainActor() {
    // currentState requires @MainActor on iOS
    let state = LockDetector.currentState
    XCTAssertEqual(state, .unlocked)
  }
}
#endif
