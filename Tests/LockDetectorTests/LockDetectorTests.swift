@testable import LockDetector
import XCTest

final class LockDetectorTests: XCTestCase {
  func testIsAppExtension() {
    XCTAssertFalse(LockDetector.isAppExtension)
  }

  @MainActor
  func testCurrentState() {
    let state = LockDetector.currentState
    XCTAssertEqual(state, .unlocked)
  }

  func testProtectedFilePathNotEmpty() {
    XCTAssertFalse(LockDetector.protectedFilePath.isEmpty)
    XCTAssertTrue(LockDetector.protectedFilePath.hasSuffix("/protected"))
  }

  func testInitialize() {
    LockDetector.initialize()
    XCTAssertTrue(FileManager.default.fileExists(atPath: LockDetector.protectedFilePath))
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
}
