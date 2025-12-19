import ActivityKit
import LockDetector
import SwiftUI
import WidgetKit

/// Widget Extension demonstrating LockDetector limitations.
///
/// **Important**: Lock detection is NOT supported in Widget Extensions.
/// `LockDetector.currentState` will always return `.unknown` in this context.
///
/// This is due to:
/// 1. **Sandbox isolation**: Widget Extensions run in a separate container
/// 2. **No UIApplication access**: Cannot use `isProtectedDataAvailable`
/// 3. **Timeline-based execution**: Widgets update at system-determined intervals
/// 4. **Lock Screen paradox**: Lock Screen widgets only display when device is locked
///
/// This widget demonstrates how to properly handle the `.unknown` state
/// and shows the extension detection APIs.
///
/// ## Live Activity
/// This extension also includes a Live Activity that CAN display real-time lock state
/// updates because:
/// 1. **Push updates**: The main app can push state changes via ActivityKit
/// 2. **App-driven**: State is determined by the main app, not the extension
/// 3. **Real-time**: Updates appear immediately on Lock Screen and Dynamic Island

// MARK: - Timeline Provider

struct LockWidgetProvider: TimelineProvider {
  func placeholder(in _: Context) -> LockWidgetEntry {
    LockWidgetEntry(date: Date(), lockState: .unknown, isWidgetExtension: true)
  }

  func getSnapshot(in _: Context, completion: @escaping (LockWidgetEntry) -> Void) {
    Task { @MainActor in
      let entry = LockWidgetEntry(
        date: Date(),
        lockState: LockDetector.currentState,
        isWidgetExtension: LockDetector.isWidgetExtension
      )
      completion(entry)
    }
  }

  func getTimeline(in _: Context, completion: @escaping (Timeline<LockWidgetEntry>) -> Void) {
    Task { @MainActor in
      // Get current state (will be .unknown in Widget Extension)
      let currentState = LockDetector.currentState

      // Log for debugging
      print("[LockWidget] isAppExtension: \(LockDetector.isAppExtension)")
      print("[LockWidget] isWidgetExtension: \(LockDetector.isWidgetExtension)")
      print("[LockWidget] currentState: \(currentState)")

      let entry = LockWidgetEntry(
        date: Date(),
        lockState: currentState,
        isWidgetExtension: LockDetector.isWidgetExtension
      )

      // Refresh every 15 minutes
      let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
      let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
      completion(timeline)
    }
  }
}

// MARK: - Timeline Entry

struct LockWidgetEntry: TimelineEntry {
  let date: Date
  let lockState: LockDetector.ScreenState
  let isWidgetExtension: Bool
}

// MARK: - Widget View

struct LockWidgetEntryView: View {
  var entry: LockWidgetEntry

  var body: some View {
    VStack(spacing: 8) {
      // State icon
      Image(systemName: iconName)
        .font(.system(size: 40))
        .foregroundColor(iconColor)

      // State description
      Text(stateDescription)
        .font(.headline)
        .multilineTextAlignment(.center)

      // Extension info
      if entry.isWidgetExtension {
        Text("Widget Extension")
          .font(.caption2)
          .foregroundColor(.secondary)
      }
    }
    .padding()
    .containerBackground(for: .widget) {
      backgroundColor
    }
  }

  private var iconName: String {
    switch entry.lockState {
    case .locked:
      "lock.fill"
    case .unlocked:
      "lock.open.fill"
    case .unknown:
      "questionmark.circle.fill"
    }
  }

  private var iconColor: Color {
    switch entry.lockState {
    case .locked:
      .red
    case .unlocked:
      .green
    case .unknown:
      .orange
    }
  }

  private var stateDescription: String {
    switch entry.lockState {
    case .locked:
      "Locked"
    case .unlocked:
      "Unlocked"
    case .unknown:
      "Not Supported"
    }
  }

  private var backgroundColor: Color {
    switch entry.lockState {
    case .locked:
      Color.red.opacity(0.1)
    case .unlocked:
      Color.green.opacity(0.1)
    case .unknown:
      Color.orange.opacity(0.1)
    }
  }
}

// MARK: - Widget Configuration

struct LockWidget: Widget {
  let kind: String = "LockWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: LockWidgetProvider()) { entry in
      LockWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("Lock State")
    .description("Demonstrates LockDetector limitations in Widget Extensions. Lock state detection is not supported - always shows 'Not Supported'.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

// MARK: - Live Activity Attributes

/// Attributes for the Lock State Live Activity.
///
/// Unlike widgets, Live Activities receive updates from the main app,
/// allowing accurate lock state display on the Lock Screen and Dynamic Island.
public struct LockActivityAttributes: ActivityAttributes {
  /// Dynamic content state that can be updated
  public struct ContentState: Codable, Hashable {
    /// Current lock state as a string (locked, unlocked, unknown)
    public var lockStateRaw: String
    /// Timestamp of the last state change
    public var lastUpdated: Date

    public init(lockState: LockDetector.ScreenState, lastUpdated: Date = Date()) {
      lockStateRaw = lockState.rawValue
      self.lastUpdated = lastUpdated
    }

    /// Convert raw value back to ScreenState
    public var lockState: LockDetector.ScreenState {
      LockDetector.ScreenState(rawValue: lockStateRaw) ?? .unknown
    }
  }

  /// Static attributes (none needed for this demo)
  public init() {}
}

// MARK: - Live Activity Configuration

struct LockActivityConfiguration: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: LockActivityAttributes.self) { context in
      // Lock Screen presentation
      LockActivityLockScreenView(context: context)
    } dynamicIsland: { context in
      DynamicIsland {
        // Expanded presentation
        DynamicIslandExpandedRegion(.leading) {
          Image(systemName: context.state.lockState.iconName)
            .font(.title2)
            .foregroundColor(context.state.lockState.color)
        }
        DynamicIslandExpandedRegion(.center) {
          Text(context.state.lockState.description)
            .font(.headline)
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text("Live")
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        DynamicIslandExpandedRegion(.bottom) {
          HStack {
            Text("Updated: \(context.state.lastUpdated, style: .time)")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
      } compactLeading: {
        Image(systemName: context.state.lockState.iconName)
          .foregroundColor(context.state.lockState.color)
      } compactTrailing: {
        Text(context.state.lockState.shortDescription)
          .font(.caption2)
      } minimal: {
        Image(systemName: context.state.lockState.iconName)
          .foregroundColor(context.state.lockState.color)
      }
    }
  }
}

// MARK: - Live Activity Lock Screen View

struct LockActivityLockScreenView: View {
  let context: ActivityViewContext<LockActivityAttributes>

  var body: some View {
    HStack(spacing: 16) {
      // State icon
      Image(systemName: context.state.lockState.iconName)
        .font(.system(size: 36))
        .foregroundColor(context.state.lockState.color)

      VStack(alignment: .leading, spacing: 4) {
        Text("Screen \(context.state.lockState.description)")
          .font(.headline)

        Text("Updated \(context.state.lastUpdated, style: .relative) ago")
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Spacer()

      // Live indicator
      HStack(spacing: 4) {
        Circle()
          .fill(.green)
          .frame(width: 6, height: 6)
        Text("LIVE")
          .font(.caption2)
          .fontWeight(.semibold)
          .foregroundColor(.green)
      }
    }
    .padding()
    .activityBackgroundTint(context.state.lockState.backgroundColor)
  }
}

// MARK: - ScreenState Extensions for Live Activity

extension LockDetector.ScreenState {
  /// Short emoji representation for compact displays
  var shortDescription: String {
    switch self {
    case .locked: "🔒"
    case .unlocked: "🔓"
    case .unknown: "❓"
    }
  }

  /// Raw string value for Codable serialization
  var rawValue: String {
    switch self {
    case .locked: "locked"
    case .unlocked: "unlocked"
    case .unknown: "unknown"
    }
  }

  /// Initialize from raw string value
  init?(rawValue: String) {
    switch rawValue {
    case "locked": self = .locked
    case "unlocked": self = .unlocked
    case "unknown": self = .unknown
    default: return nil
    }
  }
}

// MARK: - Widget Bundle

@main
struct LockWidgetBundle: WidgetBundle {
  var body: some Widget {
    LockWidget()
    LockActivityConfiguration()
  }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
  LockWidget()
} timeline: {
  LockWidgetEntry(date: .now, lockState: .unknown, isWidgetExtension: true)
  LockWidgetEntry(date: .now, lockState: .locked, isWidgetExtension: false)
  LockWidgetEntry(date: .now, lockState: .unlocked, isWidgetExtension: false)
}
