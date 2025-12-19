import LockDetector
import SwiftUI

struct ContentViewMac: View {
  @StateObject private var viewModel = LockStateViewModel()

  var body: some View {
    VStack(spacing: 20) {
      // Header
      Text("LockDetector Demo")
        .font(.largeTitle)
        .fontWeight(.bold)

      Text("macOS")
        .font(.subheadline)
        .foregroundColor(.secondary)

      Divider()

      // Current State Section
      CurrentStateSection(viewModel: viewModel)

      Divider()

      // Observation Section
      ObservationSection(viewModel: viewModel, platformHint: "Mac")

      Spacer()

      // Info
      Text("Lock your Mac (Ctrl+Cmd+Q) to test state detection")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .padding(24)
    .frame(minWidth: 400, minHeight: 650)
    .onAppear {
      viewModel.refreshCurrentState()
    }
    .onDisappear {
      viewModel.stopObserving()
    }
  }
}

// MARK: - Current State Section

private struct CurrentStateSection: View {
  @ObservedObject var viewModel: LockStateViewModel

  var body: some View {
    VStack(spacing: 12) {
      Text("Current State")
        .font(.headline)

      StateBadgeView(state: viewModel.currentState)

      Button("Refresh State") {
        viewModel.refreshCurrentState()
      }
      .buttonStyle(.borderedProminent)
    }
  }
}

// MARK: - Observation Section

private struct ObservationSection: View {
  @ObservedObject var viewModel: LockStateViewModel
  let platformHint: String

  var body: some View {
    VStack(spacing: 12) {
      Text("State Change Observation")
        .font(.headline)

      HStack(spacing: 16) {
        ObservationStatusView(isObserving: viewModel.isObserving)

        Spacer()

        Button(viewModel.isObserving ? "Stop" : "Start") {
          viewModel.toggleObservation()
        }
        .buttonStyle(.bordered)
      }
      .padding(.horizontal)

      // History Log
      HistoryLogView(viewModel: viewModel, platformHint: platformHint)

      Button("Clear History") {
        viewModel.clearHistory()
      }
      .buttonStyle(.bordered)
      .disabled(viewModel.stateHistory.isEmpty)
    }
  }
}

// MARK: - History Log View

private struct HistoryLogView: View {
  @ObservedObject var viewModel: LockStateViewModel
  let platformHint: String

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Event History")
        .font(.subheadline)
        .foregroundColor(.secondary)

      if viewModel.stateHistory.isEmpty {
        EmptyHistoryView(platformHint: platformHint)
      } else {
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 4) {
            ForEach(viewModel.reversedHistory) { event in
              CompactHistoryRow(event: event)
            }
          }
        }
        .frame(maxHeight: 150)
      }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .cornerRadius(8)
  }
}

// MARK: - Compact History Row (macOS style)

private struct CompactHistoryRow: View {
  let event: StateHistoryEvent

  var body: some View {
    HStack {
      Text(SharedFormatters.timeFormatter.string(from: event.date))
        .font(.system(.caption, design: .monospaced))
        .foregroundColor(.secondary)

      StateIconView(state: event.state)
        .font(.caption)

      Text(event.state.description)
        .font(.caption)
    }
  }
}

#Preview {
  ContentViewMac()
}
