@testable import LockDetector
import XCTest

final class LockDetectorTests: XCTestCase {
  func testCurrentState() {
    let state = LockDetector.currentState
    // On macOS (unlocked desktop) or iOS (unlocked device), should be unlocked
    XCTAssertEqual(state, .unlocked)
  }

  func testScreenStateEquality() {
    XCTAssertEqual(LockDetector.ScreenState.locked, .locked)
    XCTAssertEqual(LockDetector.ScreenState.unlocked, .unlocked)
    XCTAssertEqual(LockDetector.ScreenState.unknown, .unknown)
    XCTAssertNotEqual(LockDetector.ScreenState.locked, .unlocked)
  }

  func testObservationToken() {
    var callCount = 0
    let token = LockDetector.observeStateChanges { _ in
      callCount += 1
    }
    XCTAssertNotNil(token)

    // Invalidate should not crash
    token.invalidate()

    // Double invalidate should be safe
    token.invalidate()
  }

  // MARK: - iOS-specific tests

  #if canImport(UIKit) && !os(macOS)
    func testIsAppExtension() {
      XCTAssertFalse(LockDetector.isAppExtension)
    }

    func testProtectedFilePathNotEmpty() {
      XCTAssertFalse(LockDetector.protectedFilePath.isEmpty)
      XCTAssertTrue(LockDetector.protectedFilePath.hasSuffix("/protected"))
    }

    func testInitialize() {
      LockDetector.initialize()
      XCTAssertTrue(FileManager.default.fileExists(atPath: LockDetector.protectedFilePath))
    }
  #endif

  // MARK: - macOS-specific tests

  #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    func testMacOSCurrentStateNotUnknown() {
      // On a GUI session, should not return unknown
      let state = LockDetector.currentState
      XCTAssertNotEqual(state, .unknown)
    }
  #endif
}
