// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "TestModule",
  platforms: [.macOS(.v10_15)],
  products: [
    .library(
      name: "TestModule",
      type: .dynamic,
      targets: ["TestModule"]
    )
  ],
  dependencies: [
    .package(path: "../../..")
  ],
  targets: [
    .target(
      name: "TestModule",
      dependencies: [
        .product(name: "EmacsSwiftModuleDynamic", package: "emacs-swift-module")
      ],
      plugins: [
        .plugin(name: "ModuleFactoryPlugin", package: "emacs-swift-module")
      ]
    )
  ]
)
