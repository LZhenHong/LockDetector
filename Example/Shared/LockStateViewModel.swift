import LockDetector
import SwiftUI

/// Shared view model for lock state observation across iOS and macOS
@MainActor
public final class LockStateViewModel: ObservableObject {
  @Published public private(set) var currentState: LockDetector.ScreenState = .unknown
  @Published public private(set) var stateHistory: [StateHistoryEvent] = []
  @Published public private(set) var isObserving = false

  private var observationToken: LockDetector.ObservationToken?

  public init() {}

  deinit {
    observationToken?.invalidate()
  }

  // MARK: - Public Actions

  /// Refresh the current lock state
  public func refreshCurrentState() {
    currentState = LockDetector.currentState
  }

  /// Toggle observation on/off
  public func toggleObservation() {
    if isObserving {
      stopObserving()
    } else {
      startObserving()
    }
  }

  /// Start observing state changes
  public func startObserving() {
    guard !isObserving else { return }

    observationToken = LockDetector.observeStateChanges { [weak self] newState in
      Task { @MainActor [weak self] in
        guard let self else { return }
        currentState = newState
        stateHistory.append(StateHistoryEvent(date: Date(), state: newState))
      }
    }
    isObserving = true
  }

  /// Stop observing state changes
  public func stopObserving() {
    observationToken?.invalidate()
    observationToken = nil
    isObserving = false
  }

  /// Clear the event history
  public func clearHistory() {
    stateHistory.removeAll()
  }

  /// Get history events in reverse chronological order
  public var reversedHistory: [StateHistoryEvent] {
    stateHistory.reversed()
  }
}
