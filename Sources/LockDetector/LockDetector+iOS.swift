#if canImport(UIKit)

import UIKit

private typealias Application = UIApplication

// MARK: - iOS/Catalyst Implementation

extension LockDetector {
  // MARK: - Observation

  static func observeIOSStateChanges(_ handler: @escaping @Sendable (ScreenState) -> Void) -> ObservationToken {
    let center = NotificationCenter.default

    let unlockObserver = center.addObserver(
      forName: UIApplication.protectedDataDidBecomeAvailableNotification,
      object: nil,
      queue: .main
    ) { _ in handler(.unlocked) }

    let lockObserver = center.addObserver(
      forName: UIApplication.protectedDataWillBecomeUnavailableNotification,
      object: nil,
      queue: .main
    ) { _ in handler(.locked) }

    return ObservationToken(
      observers: [unlockObserver, lockObserver],
      removeObserver: { center.removeObserver($0) }
    )
  }

  // MARK: - App Extension Detection

  /// Whether the current process is running in an App Extension.
  public static var isAppExtension: Bool {
    guard Bundle.main.bundlePath.hasSuffix(".appex") else {
      return false
    }

    let cls: AnyClass? = NSClassFromString(String(describing: Application.self))
    guard let cls, cls.responds(to: #selector(getter: Application.shared)) else {
      return true
    }

    return false
  }

  // MARK: - Protected File

  /// Path to the protected file used for extension lock detection.
  public static var protectedFilePath: String = {
    guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
      return ""
    }
    return path + "/protected"
  }()

  private static var protectedFileExists: Bool {
    !protectedFilePath.isEmpty && FileManager.default.fileExists(atPath: protectedFilePath)
  }

  private static func createProtectedFile() {
    FileManager.default.createFile(
      atPath: protectedFilePath,
      contents: Data(),
      attributes: [.protectionKey: FileProtectionType.complete]
    )
  }

  /// Creates protected file if it doesn't exist (iOS only).
  /// Call this early in app lifecycle for App Extension support.
  public static func initialize() {
    guard !protectedFileExists else { return }
    createProtectedFile()
  }

  // MARK: - Current State

  /// Gets the current screen lock state on iOS/Catalyst.
  ///
  /// - For main apps: Uses `isProtectedDataAvailable`
  /// - For extensions: Attempts to read a protected file
  @MainActor
  public static var currentState: ScreenState {
    isAppExtension ? extensionScreenState : mainAppScreenState
  }

  @MainActor
  private static var extensionScreenState: ScreenState {
    guard protectedFileExists else {
      createProtectedFile()
      return .unknown
    }

    do {
      _ = try Data(contentsOf: URL(fileURLWithPath: protectedFilePath))
      return .unlocked
    } catch {
      return .locked
    }
  }

  @MainActor
  private static var mainAppScreenState: ScreenState {
    Application.shared.isProtectedDataAvailable ? .unlocked : .locked
  }
}
#endif
