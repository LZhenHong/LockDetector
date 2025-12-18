// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "LockDetector",
  platforms: [
    .macOS(.v12),
    .macCatalyst(.v13),
    .iOS(.v13),
  ],
  products: [
    .library(name: "LockDetector", targets: ["LockDetector"]),
  ],
  targets: [
    .target(name: "LockDetector"),
    .testTarget(name: "LockDetectorTests", dependencies: ["LockDetector"]),
  ]
)
