// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "EmacsSwiftModule",
  platforms: [.macOS(.v10_15)],
  products: [
    .library(
      name: "EmacsSwiftModule",
      targets: ["EmacsSwiftModule"]
    ),
    .plugin(
      name: "ModuleFactoryPlugin",
      targets: ["ModuleFactoryPlugin"]
    ),
    .library(
      name: "TestModule",
      type: .dynamic,
      targets: ["TestModule"]
    ),
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
    .plugin(
      name: "ModuleFactoryPlugin",
      capability: .buildTool(),
      dependencies: [.target(name: "ModuleInitializerInjector")]
    ),
    .executableTarget(
      name: "ModuleInitializerInjector",
      path: "Plugins",
      exclude: ["ModuleFactoryPlugin/ModuleFactoryPlugin.swift"],
      sources: ["ModuleInitializerInjector.swift"]
    ),
    .target(
      name: "TestModule",
      dependencies: ["EmacsSwiftModule"],
      path: "Test/TestModule",
      plugins: ["ModuleFactoryPlugin"]
    ),
  ]
)

#if swift(>=5.6)
  package.dependencies.append(
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
  )
#endif
