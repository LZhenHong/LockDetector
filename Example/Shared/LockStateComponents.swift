import LockDetector
import SwiftUI

// MARK: - ScreenState Extensions

public extension LockDetector.ScreenState {
  /// Localized description of the screen state
  var description: String {
    switch self {
    case .locked:
      "Locked"
    case .unlocked:
      "Unlocked"
    case .unknown:
      "Unknown"
    }
  }

  /// SF Symbol name for the screen state
  var iconName: String {
    switch self {
    case .locked:
      "lock.fill"
    case .unlocked:
      "lock.open.fill"
    case .unknown:
      "questionmark.circle.fill"
    }
  }

  /// Color associated with the screen state
  var color: Color {
    switch self {
    case .locked:
      .red
    case .unlocked:
      .green
    case .unknown:
      .orange
    }
  }

  /// Background color for the screen state (with opacity)
  var backgroundColor: Color {
    color.opacity(0.15)
  }
}

// MARK: - Shared UI Components

/// Icon view for displaying screen state
public struct StateIconView: View {
  let state: LockDetector.ScreenState

  public init(state: LockDetector.ScreenState) {
    self.state = state
  }

  public var body: some View {
    Image(systemName: state.iconName)
      .foregroundColor(state.color)
  }
}

/// Badge view showing current state with icon and text
public struct StateBadgeView: View {
  let state: LockDetector.ScreenState
  let iconSize: CGFloat
  let showDescription: Bool

  public init(
    state: LockDetector.ScreenState,
    iconSize: CGFloat = 40,
    showDescription: Bool = true
  ) {
    self.state = state
    self.iconSize = iconSize
    self.showDescription = showDescription
  }

  public var body: some View {
    HStack(spacing: 12) {
      StateIconView(state: state)
        .font(.system(size: iconSize))

      if showDescription {
        Text(state.description)
          .font(.title2)
          .fontWeight(.semibold)
      }
    }
    .padding()
    .background(state.backgroundColor)
    .cornerRadius(12)
  }
}

/// Observation status indicator
public struct ObservationStatusView: View {
  let isObserving: Bool

  public init(isObserving: Bool) {
    self.isObserving = isObserving
  }

  public var body: some View {
    HStack(spacing: 8) {
      Circle()
        .fill(isObserving ? Color.green : Color.gray)
        .frame(width: 10, height: 10)

      Text(isObserving ? "Active" : "Inactive")
        .font(.caption)
        .foregroundColor(isObserving ? .green : .secondary)
    }
  }
}

// MARK: - Event History

/// A single history event
public struct StateHistoryEvent: Identifiable {
  public let id = UUID()
  public let date: Date
  public let state: LockDetector.ScreenState

  public init(date: Date, state: LockDetector.ScreenState) {
    self.date = date
    self.state = state
  }
}

/// Row view for displaying a history event
public struct HistoryEventRow: View {
  let event: StateHistoryEvent
  let dateFormatter: DateFormatter

  public init(event: StateHistoryEvent, dateFormatter: DateFormatter) {
    self.event = event
    self.dateFormatter = dateFormatter
  }

  public var body: some View {
    HStack(spacing: 12) {
      StateIconView(state: event.state)
        .font(.title3)

      VStack(alignment: .leading, spacing: 2) {
        Text(event.state.description)
          .font(.subheadline)
          .fontWeight(.medium)

        Text(dateFormatter.string(from: event.date))
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Spacer()
    }
  }
}

/// Empty state view for history
public struct EmptyHistoryView: View {
  let platformHint: String

  public init(platformHint: String = "device") {
    self.platformHint = platformHint
  }

  public var body: some View {
    VStack(spacing: 8) {
      Image(systemName: "clock.badge.questionmark")
        .font(.system(size: 40))
        .foregroundColor(.secondary)

      Text("No events yet")
        .font(.subheadline)
        .foregroundColor(.secondary)

      Text("Start observing and lock/unlock your \(platformHint)")
        .font(.caption)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 24)
  }
}

// MARK: - Shared Utilities

/// Shared date formatter for time display
public enum SharedFormatters {
  public static let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return formatter
  }()
}
