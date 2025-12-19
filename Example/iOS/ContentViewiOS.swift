import LockDetector
import SwiftUI

struct ContentViewiOS: View {
  @StateObject private var viewModel = LockStateViewModel()

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 24) {
          // Current State Card
          CurrentStateCard(viewModel: viewModel)

          // Observation Card
          ObservationCard(viewModel: viewModel)

          // History Card
          HistoryCard(viewModel: viewModel)

          // Info Section
          InfoSection()
        }
        .padding()
      }
      .background(Color(.systemGroupedBackground))
      .navigationTitle("LockDetector")
      .navigationBarTitleDisplayMode(.large)
    }
    .onAppear {
      viewModel.refreshCurrentState()
    }
    .onDisappear {
      viewModel.stopObserving()
    }
  }
}

// MARK: - Current State Card

private struct CurrentStateCard: View {
  @ObservedObject var viewModel: LockStateViewModel

  var body: some View {
    VStack(spacing: 16) {
      Text("Current State")
        .font(.headline)
        .foregroundColor(.secondary)

      HStack(spacing: 16) {
        StateIconView(state: viewModel.currentState)
          .font(.system(size: 50))

        VStack(alignment: .leading) {
          Text(viewModel.currentState.description)
            .font(.title)
            .fontWeight(.bold)

          Text("Screen \(viewModel.currentState.description.lowercased())")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
      }
      .padding()
      .frame(maxWidth: .infinity)
      .background(viewModel.currentState.backgroundColor)
      .cornerRadius(16)

      Button(action: { viewModel.refreshCurrentState() }) {
        Label("Refresh State", systemImage: "arrow.clockwise")
      }
      .buttonStyle(.borderedProminent)
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(16)
    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
  }
}

// MARK: - Observation Card

private struct ObservationCard: View {
  @ObservedObject var viewModel: LockStateViewModel

  var body: some View {
    VStack(spacing: 16) {
      HStack {
        Text("State Observation")
          .font(.headline)

        Spacer()

        ObservationStatusView(isObserving: viewModel.isObserving)
      }

      Button(action: { viewModel.toggleObservation() }) {
        HStack {
          Image(systemName: viewModel.isObserving ? "stop.fill" : "play.fill")
          Text(viewModel.isObserving ? "Stop Observing" : "Start Observing")
        }
        .frame(maxWidth: .infinity)
      }
      .buttonStyle(.bordered)
      .tint(viewModel.isObserving ? .red : .blue)
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(16)
    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
  }
}

// MARK: - History Card

private struct HistoryCard: View {
  @ObservedObject var viewModel: LockStateViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("Event History")
          .font(.headline)

        Spacer()

        if !viewModel.stateHistory.isEmpty {
          Button("Clear") {
            viewModel.clearHistory()
          }
          .font(.caption)
        }
      }

      if viewModel.stateHistory.isEmpty {
        EmptyHistoryView(platformHint: "device")
      } else {
        ForEach(Array(viewModel.reversedHistory.enumerated()), id: \.element.id) { index, event in
          HistoryEventRow(event: event, dateFormatter: SharedFormatters.timeFormatter)
            .padding(.vertical, 8)

          if index < viewModel.stateHistory.count - 1 {
            Divider()
          }
        }
      }
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(16)
    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
  }
}

// MARK: - Info Section

private struct InfoSection: View {
  var body: some View {
    VStack(spacing: 8) {
      Label(
        "App Extension: \(LockDetector.isAppExtension ? "Yes" : "No")",
        systemImage: "puzzlepiece.extension"
      )
      Label(
        "Protected File: \(LockDetector.protectedFilePath.isEmpty ? "N/A" : "Created")",
        systemImage: "doc.badge.lock"
      )
    }
    .font(.caption)
    .foregroundColor(.secondary)
    .padding()
  }
}

#Preview {
  ContentViewiOS()
}
