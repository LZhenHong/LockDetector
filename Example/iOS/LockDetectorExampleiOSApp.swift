import LockDetector
import SwiftUI

@main
struct LockDetectorExampleiOSApp: App {
  init() {
    // Initialize LockDetector early for App Extension support
    LockDetector.initialize()
  }

  var body: some Scene {
    WindowGroup {
      ContentViewiOS()
    }
  }
}
