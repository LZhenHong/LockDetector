@testable import LockDetector
import XCTest

final class LockDetectorTests: XCTestCase {
    func testIsAppExtension() {
        XCTAssertFalse(LockDetector.isAppExtension)
    }

    func testLockState() {
        let state = LockDetector.currentState
        XCTAssertEqual(state, .unlocked)
    }
}
