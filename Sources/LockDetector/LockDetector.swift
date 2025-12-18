import Foundation

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import AppKit

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

    fileprivate init(observers: [NSObjectProtocol]) {
      self.observers = observers
    }

    /// Stops observing lock state changes.
    public func invalidate() {
      observers.forEach { NotificationCenter.default.removeObserver($0) }
      observers.removeAll()
    }

    deinit {
      invalidate()
    }
  }

  /// Observes lock state changes and calls the handler when state changes.
  /// - Parameter handler: Called with `.locked` when device locks, `.unlocked` when unlocks.
  /// - Returns: Token to manage observation. Call `invalidate()` or let it deinit to stop.
  /// - Note: Not available in App Extensions. Use polling with `currentState` instead.
  @discardableResult
  public static func observeStateChanges(_ handler: @escaping (ScreenState) -> Void) -> ObservationToken {
    let center = NotificationCenter.default

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
      let didBecomeAvailable = NSNotification.Name.NSApplicationProtectedDataDidBecomeAvailable
      let willBecomeUnavailable = NSNotification.Name.NSApplicationProtectedDataWillBecomeUnavailable
    #else
      let didBecomeAvailable = UIApplication.protectedDataDidBecomeAvailableNotification
      let willBecomeUnavailable = UIApplication.protectedDataWillBecomeUnavailableNotification
    #endif

    let unlockObserver = center.addObserver(
      forName: didBecomeAvailable,
      object: nil,
      queue: .main
    ) { _ in
      handler(.unlocked)
    }

    let lockObserver = center.addObserver(
      forName: willBecomeUnavailable,
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
    FileManager.default.createFile(atPath: path,
                                   contents: "".data(using: .utf8),
                                   attributes: [FileAttributeKey.protectionKey: FileProtectionType.complete])
  }

  private static func isProtectedFileExists() -> Bool {
    guard !protectedFilePath.isEmpty,
          FileManager.default.fileExists(atPath: protectedFilePath)
    else {
      return false
    }
    return true
  }

  /// Creates protected file if it doesn't exist.
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
    Application.shared.isProtectedDataAvailable ? ScreenState.unlocked : ScreenState.locked
  }
}
