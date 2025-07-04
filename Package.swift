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
    .library(
      name: "EmacsSwiftModuleDynamic",
      type: .dynamic,
      targets: ["EmacsSwiftModule"]
    ),
    .plugin(
      name: "ModuleFactoryPlugin",
      targets: ["ModuleFactoryPlugin"]
    )
  ],
  dependencies: [],
  targets: [
    .target(
      name: "EmacsSwiftModule",
      dependencies: ["EmacsModule"],
      path: "Source/Swift",
      swiftSettings: [
        // It looks like it is a Swift compiler flag, that CMO
        // leads to removal of some of the Emacs C definitions and
        // linking errors as the result.
        .unsafeFlags(["-disable-cmo"], .when(platforms: [.linux]))
      ]
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
      name: "EmacsEnvMock",
      dependencies: ["EmacsModule"],
      path: "test/Unit/Mock/C",
      publicHeadersPath: "include"
    ),
    .testTarget(
      name: "EmacsSwiftModuleTests",
      dependencies: ["EmacsSwiftModule", "EmacsEnvMock"],
      path: "test",
      exclude: ["Unit/Mock/C", "Integration/TestModule"],
      swiftSettings: [
        .define("LEAKS", .when(configuration: .debug)),
        .define("DEBUG", .when(configuration: .debug)),
        .define("RELEASE", .when(configuration: .release))
      ]
    )
  ]
)

#if swift(>=5.6)
  package.dependencies.append(
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
  )
#endif
