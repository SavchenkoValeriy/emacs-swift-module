// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "EmacsSwiftModule",
  platforms: [.macOS(.v10_15)],
  products: [
    .library(
      name: "EmacsSwiftModule",
      targets: ["EmacsSwiftModule"]),
    .library(
      name: "TestModule",
      type: .dynamic,
      targets: ["TestModule"]),
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
    ),
  ]
)

#if swift(>=5.6)
  package.dependencies.append(
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
  )
#endif
