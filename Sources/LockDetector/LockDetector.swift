import Foundation

// MARK: - LockDetector

/// Detects whether the device screen is locked or unlocked.
///
/// Usage:
/// ```swift
/// // Get current state
/// let state = LockDetector.currentState
///
/// // Observe changes
/// let token = LockDetector.observeStateChanges { state in
///     print("Screen is now \(state)")
/// }
/// ```
public enum LockDetector {
  // MARK: - Types

  /// Represents the current screen lock state.
  public enum ScreenState: Sendable {
    case unknown
    case locked
    case unlocked
  }

  /// Token for managing notification observation lifecycle.
  /// Store this token and call `invalidate()` when done, or let it deinit.
  public final class ObservationToken: @unchecked Sendable {
    private var observers: [NSObjectProtocol] = []
    private let removeObserver: (NSObjectProtocol) -> Void

    init(
      observers: [NSObjectProtocol],
      removeObserver: @escaping (NSObjectProtocol) -> Void
    ) {
      self.observers = observers
      self.removeObserver = removeObserver
    }

    /// Stops observing lock state changes.
    public func invalidate() {
      observers.forEach(removeObserver)
      observers.removeAll()
    }

    deinit {
      invalidate()
    }
  }

  // MARK: - Public API

  /// Observes lock state changes and calls the handler when state changes.
  /// - Parameter handler: Called with `.locked` when device locks, `.unlocked` when unlocks.
  /// - Returns: Token to manage observation. Call `invalidate()` or let it deinit to stop.
  /// - Note: On iOS App Extensions, use polling with `currentState` instead.
  @discardableResult
  public static func observeStateChanges(_ handler: @escaping @Sendable (ScreenState) -> Void) -> ObservationToken {
    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    return observeMacOSStateChanges(handler)
    #else
    return observeIOSStateChanges(handler)
    #endif
  }
}
