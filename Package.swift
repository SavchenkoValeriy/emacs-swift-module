// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "EmacsSwiftModule",
  platforms: [.macOS(.v10_15)],
  products: [
    .library(
      name: "TestModule",
      type: .dynamic,
      targets: ["TestModule"])
  ],
  dependencies: [],
  targets: [
    .target(
      name: "EmacsSwiftModule",
      dependencies: ["EmacsModule"],
      path: "Source/Swift"
    ),
    .target(
      name: "EmacsModule",
      dependencies: [],
      path: "Source/C",
      publicHeadersPath: "include"
    ),
    .target(
      name: "TestModule",
      dependencies: ["EmacsSwiftModule"],
      path: "Test/TestModule"
    )
  ]
)
