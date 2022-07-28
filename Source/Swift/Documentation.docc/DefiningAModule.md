# Defining a module

Defining a new Emacs module from Swift.

## EmacsSwiftModule installation

### Swift Package Manager

Add the following line to you package dependencies:

```swift
.package("https://github.com/SavchenkoValeriy/emacs-swift-module.git", from: "1.0.0")
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
  ]
```

## Writing a module code

Each module is required to have two exported C functions: `plugin_is_GPL_compatible` and `emacs_module_init`. The first one is the way to tell Emacs that your code is GPL-compatible. The second function is your module's `main` function. It is called when Emacs loads your module.

Of course, we can define these two functions from Swift and this is how you'd typically do this.

```swift
import EmacsSwiftModule

@_cdecl("plugin_is_GPL_compatible")
public func isGPLCompatible() {}

@_cdecl("emacs_module_init")
public func Init(_ runtimePtr: RuntimePointer) -> Int32 {
  let env = Environment(from: runtimePtr)
  do {
    // initialize your module here
    try env.funcall("message", "Hello from Swift!")
  } catch {
    return 1
  }
  return 0
}
```

This should be the only reminder of us working directly with a C interface. ``Environment`` is your entry-point into the Emacs world from Swift.

Now, if you compile this code with `swift build` and load it from Emacs via 
```emacs-lisp
(module-load "SOURCE_DIR/.build/debug/libYOUR_MODULE_NAME.dylib")
```
you should see the `"Hello from Swift!"` message in your Emacs.

> Important: Don't throw exceptions in your init methods, crashing the module is the same as crashing the whole Emacs. That's not what Emacs users expect from their plugins!
