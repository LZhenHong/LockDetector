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

// MARK: - Widget Bundle

@main
struct LockWidgetBundle: WidgetBundle {
  var body: some Widget {
    LockWidget()
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
