import Foundation

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import AppKit
  import CoreGraphics

  typealias Application = NSApplication
#elseif canImport(UIKit)
  import UIKit

  typealias Application = UIApplication
#endif

public enum LockDetector {
  public enum ScreenState {
    case unknown, locked, unlocked
  }

  /// Token for managing notification observation lifecycle.
  public final class ObservationToken {
    private var observers: [NSObjectProtocol] = []
    private var notificationCenter: Any?

    fileprivate init(observers: [NSObjectProtocol], notificationCenter: Any? = nil) {
      self.observers = observers
      self.notificationCenter = notificationCenter
    }

    /// Stops observing lock state changes.
    public func invalidate() {
      #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        // macOS uses DistributedNotificationCenter
        let center = DistributedNotificationCenter.default()
        observers.forEach { center.removeObserver($0) }
      #else
        // iOS uses NotificationCenter
        observers.forEach { NotificationCenter.default.removeObserver($0) }
      #endif
      observers.removeAll()
    }

    deinit {
      invalidate()
    }
  }

  // MARK: - Observation

  /// Observes lock state changes and calls the handler when state changes.
  /// - Parameter handler: Called with `.locked` when device locks, `.unlocked` when unlocks.
  /// - Returns: Token to manage observation. Call `invalidate()` or let it deinit to stop.
  /// - Note: On iOS App Extensions, use polling with `currentState` instead.
  @discardableResult
  public static func observeStateChanges(_ handler: @escaping (ScreenState) -> Void) -> ObservationToken {
    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
      // macOS: Use DistributedNotificationCenter for reliable lock detection
      return observeMacOSStateChanges(handler)
    #else
      // iOS/Catalyst: Use protected data notifications
      return observeIOSStateChanges(handler)
    #endif
  }

  #if canImport(AppKit) && !targetEnvironment(macCatalyst)

    // MARK: - macOS Implementation

    private static let screenIsLockedNotification = Notification.Name("com.apple.screenIsLocked")
    private static let screenIsUnlockedNotification = Notification.Name("com.apple.screenIsUnlocked")

    private static func observeMacOSStateChanges(_ handler: @escaping (ScreenState) -> Void) -> ObservationToken {
      let center = DistributedNotificationCenter.default()

      let lockObserver = center.addObserver(
        forName: screenIsLockedNotification,
        object: nil,
        queue: .main
      ) { _ in
        handler(.locked)
      }

      let unlockObserver = center.addObserver(
        forName: screenIsUnlockedNotification,
        object: nil,
        queue: .main
      ) { _ in
        handler(.unlocked)
      }

      return ObservationToken(observers: [lockObserver, unlockObserver], notificationCenter: center)
    }

    /// Gets the current screen lock state on macOS using CGSessionCopyCurrentDictionary.
    public static var currentState: ScreenState {
      guard let dict = CGSessionCopyCurrentDictionary() as? [String: Any] else {
        // Not running in a GUI session
        return .unknown
      }

      // CGSSessionScreenIsLocked key is only present when screen is locked
      if let isLocked = dict["CGSSessionScreenIsLocked"] as? Bool {
        return isLocked ? .locked : .unlocked
      }

      // Key not present means screen is unlocked
      return .unlocked
    }

  #else

    // MARK: - iOS/Catalyst Implementation

    private static func observeIOSStateChanges(_ handler: @escaping (ScreenState) -> Void) -> ObservationToken {
      let center = NotificationCenter.default

      let unlockObserver = center.addObserver(
        forName: UIApplication.protectedDataDidBecomeAvailableNotification,
        object: nil,
        queue: .main
      ) { _ in
        handler(.unlocked)
      }

      let lockObserver = center.addObserver(
        forName: UIApplication.protectedDataWillBecomeUnavailableNotification,
        object: nil,
        queue: .main
      ) { _ in
        handler(.locked)
      }

      return ObservationToken(observers: [unlockObserver, lockObserver])
    }

    public static var isAppExtension: Bool {
      // First check bundle path - if not .appex, definitely not an extension
      guard Bundle.main.bundlePath.hasSuffix(".appex") else {
        return false
      }

      // In App Extensions, Application.shared is not accessible
      let cls: AnyClass? = NSClassFromString(String(describing: Application.self))
      guard let cls, cls.responds(to: #selector(getter: Application.shared)) else {
        return true // Cannot access Application.shared = is an extension
      }

      return false
    }

    public static var protectedFilePath: String = {
      guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
        return ""
      }
      return path + "/protected"
    }()

    // https://developer.apple.com/documentation/foundation/fileprotectiontype/1616200-complete
    private static func createProtectedFile(with path: String) {
      FileManager.default.createFile(
        atPath: path,
        contents: "".data(using: .utf8),
        attributes: [FileAttributeKey.protectionKey: FileProtectionType.complete]
      )
    }

    private static func isProtectedFileExists() -> Bool {
      guard !protectedFilePath.isEmpty,
            FileManager.default.fileExists(atPath: protectedFilePath)
      else {
        return false
      }
      return true
    }

    /// Creates protected file if it doesn't exist (iOS only).
    public static func initialize() {
      guard !isProtectedFileExists() else {
        return
      }
      createProtectedFile(with: protectedFilePath)
    }

    @MainActor
    public static var currentState: ScreenState {
      isAppExtension ? extensionAppScreenState : mainAppScreenState
    }

    @MainActor
    private static var extensionAppScreenState: ScreenState {
      guard isProtectedFileExists() else {
        createProtectedFile(with: protectedFilePath)
        return .unknown
      }

      do {
        _ = try String(contentsOfFile: protectedFilePath, encoding: .utf8)
      } catch {
        return .locked
      }
      return .unlocked
    }

    @MainActor
    private static var mainAppScreenState: ScreenState {
      Application.shared.isProtectedDataAvailable ? .unlocked : .locked
    }
  #endif
}
