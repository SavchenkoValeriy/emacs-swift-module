# Defining a module

Defining a new Emacs module from Swift.

## EmacsSwiftModule installation

### Swift Package Manager

Add the following line to you package dependencies:

```swift
.package("https://github.com/SavchenkoValeriy/emacs-swift-module.git", from: "1.3.4")
```

Or add `"https://github.com/SavchenkoValeriy/emacs-swift-module.git"` directly via Xcode.

## Module library

Make sure that you have a dynamic library product for your module target similar to the following code:

```swift
products: [
  .library(
    name: "AwesomeSwiftEmacsModule",
    type: .dynamic,
    targets: ["AwesomeSwiftEmacsModule"]),
],
dependencies: [
  .package("https://github.com/SavchenkoValeriy/emacs-swift-module.git", from: "1.3.4")
],
targets: [
  .target(
    name: "AwesomeSwiftEmacsModule",
    dependencies: [
      .product(name: "EmacsSwiftModuleDynamic", package: "emacs-swift-module")
    ],
    plugins: [
      .plugin(name: "ModuleFactoryPlugin", package: "emacs-swift-module")
    ]
  )
]
```

And the target should depend on the `ModuleFactoryPlugin` to automatically setup C definitions required for each dynamic module.

## Writing a module code

Each module should have a class conforming to ``Module``. This protocol has only two requirements:
 - ``Module/isGPLCompatible``, a boolean property that should always return true telling Emacs that your code is GPL-compatible.
 - ``Module/Init(_:)``, your module's `main` function, it is called when Emacs loads your module.

```swift
import EmacsSwiftModule

class AwesomeSwiftEmacsModule: Module {
  let isGPLCompatible = true
  func Init(_ env: Environment) throws {
    // initialize your module here
    try env.funcall("message", "Hello from Swift!")
  }
}

func createModule() -> Module { AwesomeSwiftEmacsModule() }
```

Now, if you compile this code with `swift build` and load it from Emacs via 
```emacs-lisp
(module-load "SOURCE_DIR/.build/debug/libYOUR_MODULE_NAME.dylib")
```
you should see the `"Hello from Swift!"` message in your Emacs.

> Important: Uncaught exceptions in the `Init` method prevent your module from loading, use that only when you absolutely cannot proceed.
