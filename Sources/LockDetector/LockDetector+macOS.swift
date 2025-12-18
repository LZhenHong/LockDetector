#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import CoreGraphics

// MARK: - macOS Implementation

extension LockDetector {
  // MARK: - Private Constants

  private enum Notifications {
    static let screenIsLocked = Notification.Name("com.apple.screenIsLocked")
    static let screenIsUnlocked = Notification.Name("com.apple.screenIsUnlocked")
  }

  private enum SessionKeys {
    static let screenIsLocked = "CGSSessionScreenIsLocked"
  }

  // MARK: - Observation

  static func observeMacOSStateChanges(_ handler: @escaping @Sendable (ScreenState) -> Void) -> ObservationToken {
    let center = DistributedNotificationCenter.default()

    let lockObserver = center.addObserver(
      forName: Notifications.screenIsLocked,
      object: nil,
      queue: .main
    ) { _ in handler(.locked) }

    let unlockObserver = center.addObserver(
      forName: Notifications.screenIsUnlocked,
      object: nil,
      queue: .main
    ) { _ in handler(.unlocked) }

    return ObservationToken(
      observers: [lockObserver, unlockObserver],
      removeObserver: { center.removeObserver($0) }
    )
  }

  // MARK: - Current State

  /// Gets the current screen lock state on macOS.
  ///
  /// Uses `CGSessionCopyCurrentDictionary()` to read the session lock state.
  /// Returns `.unknown` if not running in a GUI session.
  public static var currentState: ScreenState {
    guard let dict = CGSessionCopyCurrentDictionary() as? [String: Any] else {
      return .unknown
    }

    if let isLocked = dict[SessionKeys.screenIsLocked] as? Bool {
      return isLocked ? .locked : .unlocked
    }

    return .unlocked
  }
}

#endif
