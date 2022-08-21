# EmacsSwiftModule 
[![Emacs](https://img.shields.io/badge/Emacs-25.3%2B-blueviolet)](https://www.gnu.org/software/emacs/) [![Swift Compatibility](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FSavchenkoValeriy%2Femacs-swift-module%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/SavchenkoValeriy/emacs-swift-module) [![OS](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FSavchenkoValeriy%2Femacs-swift-module%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/SavchenkoValeriy/emacs-swift-module) [![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

A Swift library to write Emacs plugins in Swift!

## Overview

Emacs Swift module provides a convenient API for writing [dynamic modules for Emacs](https://www.gnu.org/software/emacs/manual/html_node/elisp/Writing-Dynamic-Modules.html) in Swift. It marries a dynamic nature of Emacs Lisp with strong static typization of Swift and hides the roughness of the original C API together with harder aspects of that language such as a lack of closures and manual memory management. It also translates Emacs Lisp errors and Swift exceptions into each other.

## A Quick Tour

`EmacsSwiftModule` allows you to call functions from Emacs Lisp using Swift's own types.
```swift
let two: Int = try env.funcall("+", with: 1, 1)
assert(two == 2)
try env.funcall("message", with: "%S %S", "Hello", 42)
```

And define your own Lisp functions out of Swift closures
```swift
try env.defun("foo") {
  (x: Int, y: Int) in x + y
}
try env.defun("bar") {
  (input: [String]) in input.joined(separator: ", ")
}
```
that can be easily used in Emacs Lisp
```emacs-lisp
(foo 1 1) ;; => 2
(bar ["Hello" "World"]) ;; => "Hello, World"
```

It handles errors on both sides so the user can almost always simply ignore them.
```swift
try env.defun("always-throws") { (x: Int) throws in
  throw MyError(x: x)
}
try env.defun("calls-afdsiufs") {
  (env: Environment) in
  do {
    try env.funcall("afdsiufs", with: 42)
  } catch EmacsError.signal {
    print("Whoops! It looks like 'afdsiufs' doesn't exist!")
  }
}
```

And on the Lisp side too
```emacs-lisp
(always-throws 42) ;; => raises (swift-error "Swift exception: MyError(x: 42)")
(calls-afdsiufs) ;; => nil because we caught the error
```

The same happens when a type requirement expected in Swift is not met.
```emacs-lisp
(foo "Hello" "World") ;; => raises (wrong-type-argument numberp "Hello")
```

## Documentation

Full documentation of the package can be found here: https://savchenkovaleriy.github.io/emacs-swift-module/documentation/emacsswiftmodule/

## Installation

### Swift Package Manager

Add the following line to you package dependencies:

```swift
.package("https://github.com/SavchenkoValeriy/emacs-swift-module.git", from: "1.3.0")
```

Or add `"https://github.com/SavchenkoValeriy/emacs-swift-module.git"` directly via Xcode.

## Contribute

All contributions are most welcome!

It might include any help: bug reports, questions on how to use it, feature suggestions, and documentation updates.

## License

[GPL-3.0](./LICENSE)
