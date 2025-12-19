import ActivityKit
import LockDetector
import SwiftUI

// MARK: - Live Activity Attributes (shared with Widget Extension)

/// Attributes for the Lock State Live Activity.
///
/// This struct must be identical to the one in the Widget Extension.
/// Live Activities receive updates from the main app, allowing accurate
/// lock state display on the Lock Screen and Dynamic Island.
struct LockActivityAttributes: ActivityAttributes {
  /// Dynamic content state that can be updated
  struct ContentState: Codable, Hashable {
    /// Current lock state as a string (locked, unlocked, unknown)
    var lockStateRaw: String
    /// Timestamp of the last state change
    var lastUpdated: Date

    init(lockState: LockDetector.ScreenState, lastUpdated: Date = Date()) {
      lockStateRaw = lockState.rawValue
      self.lastUpdated = lastUpdated
    }

    /// Convert raw value back to ScreenState
    var lockState: LockDetector.ScreenState {
      LockDetector.ScreenState(rawValue: lockStateRaw) ?? .unknown
    }
  }

  /// Static attributes (none needed for this demo)
  init() {}
}

// MARK: - ScreenState rawValue Extension

extension LockDetector.ScreenState {
  var rawValue: String {
    switch self {
    case .locked: "locked"
    case .unlocked: "unlocked"
    case .unknown: "unknown"
    }
  }

  init?(rawValue: String) {
    switch rawValue {
    case "locked": self = .locked
    case "unlocked": self = .unlocked
    case "unknown": self = .unknown
    default: return nil
    }
  }
}

// MARK: - Live Activity Manager

/// Manages Live Activity lifecycle for lock state monitoring.
///
/// This manager handles starting, updating, and stopping the Live Activity
/// that displays the current lock state on the Lock Screen and Dynamic Island.
@MainActor
final class LiveActivityManager: ObservableObject {
  /// The currently active Live Activity, if any
  @Published private(set) var currentActivity: Activity<LockActivityAttributes>?

  /// Whether a Live Activity is currently running
  var isActivityRunning: Bool {
    currentActivity != nil
  }

  /// Whether Live Activities are supported and enabled
  var areActivitiesEnabled: Bool {
    ActivityAuthorizationInfo().areActivitiesEnabled
  }

  /// Start a new Live Activity with the current lock state
  func startActivity(with state: LockDetector.ScreenState) {
    guard areActivitiesEnabled else {
      print("[LiveActivity] Activities not enabled")
      return
    }

    // End any existing activity first
    if currentActivity != nil {
      endActivity()
    }

    let attributes = LockActivityAttributes()
    let contentState = LockActivityAttributes.ContentState(lockState: state)

    do {
      let activity = try Activity.request(
        attributes: attributes,
        content: .init(state: contentState, staleDate: nil),
        pushType: nil
      )
      currentActivity = activity
      print("[LiveActivity] Started with state: \(state)")
    } catch {
      print("[LiveActivity] Failed to start: \(error)")
    }
  }

  /// Update the current Live Activity with a new state
  func updateActivity(with state: LockDetector.ScreenState) {
    guard let activity = currentActivity else {
      print("[LiveActivity] No activity to update")
      return
    }

    let contentState = LockActivityAttributes.ContentState(lockState: state)

    Task {
      await activity.update(
        ActivityContent(state: contentState, staleDate: nil)
      )
      print("[LiveActivity] Updated to state: \(state)")
    }
  }

  /// End the current Live Activity
  func endActivity() {
    guard let activity = currentActivity else { return }

    Task {
      let finalState = LockActivityAttributes.ContentState(
        lockState: LockDetector.currentState
      )
      await activity.end(
        ActivityContent(state: finalState, staleDate: nil),
        dismissalPolicy: .immediate
      )
      print("[LiveActivity] Ended")
    }
    currentActivity = nil
  }

  /// Toggle Live Activity on/off
  func toggleActivity(currentState: LockDetector.ScreenState) {
    if isActivityRunning {
      endActivity()
    } else {
      startActivity(with: currentState)
    }
  }
}
