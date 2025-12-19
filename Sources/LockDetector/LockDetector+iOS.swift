#if canImport(UIKit)

import UIKit

private typealias Application = UIApplication

// MARK: - iOS/Catalyst Implementation

public extension LockDetector {
  // MARK: - Observation

  internal static func observeIOSStateChanges(_ handler: @escaping @Sendable (ScreenState) -> Void) -> ObservationToken {
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
  static var isAppExtension: Bool {
    // App Extensions have bundle paths ending in .appex
    // This is more reliable than checking UIApplication availability
    // since Widget Extensions link UIKit but can't use UIApplication.shared
    Bundle.main.bundlePath.hasSuffix(".appex")
  }

  /// Whether the current process is running in a Widget Extension.
  ///
  /// Widget Extensions run in a separate sandbox and have significant limitations:
  /// - No access to `UIApplication.shared`
  /// - Separate container from the main app (cannot share files without App Groups)
  /// - Timeline-based execution (not real-time)
  /// - Lock Screen widgets only display when the device is locked
  ///
  /// Due to these limitations, lock detection is not supported in Widget Extensions.
  /// `currentState` returns `.unknown` when running in a Widget Extension.
  static var isWidgetExtension: Bool {
    guard isAppExtension else { return false }
    // Check the extension point identifier in Info.plist
    guard let extensionInfo = Bundle.main.infoDictionary?["NSExtension"] as? [String: Any],
          let pointIdentifier = extensionInfo["NSExtensionPointIdentifier"] as? String
    else {
      return false
    }
    return pointIdentifier == "com.apple.widgetkit-extension"
  }

  // MARK: - Protected File

  /// Path to the protected file used for extension lock detection.
  /// Uses Library/Caches directory which has better accessibility than Documents.
  static var protectedFilePath: String = {
    // Use caches directory - more accessible than documents
    guard let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first else {
      return ""
    }
    return path + "/.lock_detector"
  }()

  private static var protectedFileExists: Bool {
    guard !protectedFilePath.isEmpty else { return false }
    return FileManager.default.fileExists(atPath: protectedFilePath)
  }

  private static func createProtectedFile() -> Bool {
    guard !protectedFilePath.isEmpty else { return false }
    // Use .complete protection - file is unreadable when device is locked
    // This is required for accurate lock state detection
    return FileManager.default.createFile(
      atPath: protectedFilePath,
      contents: Data(),
      attributes: [.protectionKey: FileProtectionType.complete]
    )
  }

  /// Creates protected file if it doesn't exist (iOS only).
  /// Call this early in app lifecycle (when device is unlocked) for App Extension support.
  /// - Returns: `true` if file exists or was created successfully.
  @discardableResult
  static func initialize() -> Bool {
    if protectedFileExists { return true }
    return createProtectedFile()
  }

  // MARK: - Current State

  /// Gets the current screen lock state on iOS/Catalyst.
  ///
  /// - For main apps: Uses `isProtectedDataAvailable`
  /// - For app extensions (non-widget): Attempts to read a protected file
  /// - For widget extensions: Returns `.unknown` (not supported)
  ///
  /// ## Widget Extension Limitation
  ///
  /// Lock detection is **not supported** in Widget Extensions. This method returns `.unknown`
  /// when called from a Widget Extension due to the following technical constraints:
  ///
  /// 1. **Sandbox isolation**: Widget Extensions run in a separate container from the main app.
  ///    They cannot access the main app's protected files without App Groups configuration.
  ///
  /// 2. **No UIApplication access**: Widget Extensions cannot use `UIApplication.shared`,
  ///    which is required for the `isProtectedDataAvailable` check.
  ///
  /// 3. **Timeline-based execution**: Widgets update via `TimelineProvider` at system-determined
  ///    intervals, not in real-time. They cannot respond to lock/unlock events.
  ///
  /// 4. **Lock Screen paradox**: Lock Screen widgets only display when the device is locked,
  ///    making lock detection semantically meaningless in that context.
  ///
  /// For other App Extensions (Today, Share, etc.), call `initialize()` from the main app
  /// while the device is unlocked to enable lock detection.
  @MainActor
  static var currentState: ScreenState {
    if isWidgetExtension {
      return .unknown
    }
    return isAppExtension ? extensionScreenState : mainAppScreenState
  }

  @MainActor
  private static var extensionScreenState: ScreenState {
    // If path is empty, we can't determine state
    guard !protectedFilePath.isEmpty else {
      return .unknown
    }

    // Check if file exists first
    guard protectedFileExists else {
      // File doesn't exist - try to create it (will only work if device is unlocked)
      // If creation fails, we can't determine state
      if createProtectedFile() {
        return .unlocked // We just created it, so device must be unlocked
      }
      return .unknown
    }

    // Try to read the protected file
    // If readable → unlocked, if not readable → locked
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
