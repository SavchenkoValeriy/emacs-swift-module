# ``EmacsSwiftModule``

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


## Topics

### Getting started

- <doc:DefiningAModule>
- <doc:CallingLispFunctions>
- <doc:DefiningLispFunctions>
- <doc:TypeConversions>
- <doc:ErrorHandling>

### Advanced

- <doc:Lifetimes>
- <doc:AsyncCallbacks>

### Environment

- ``Environment``
- ``RuntimePointer``

### Type conversions

- <doc:TypeConversions>
- ``EmacsConvertible``
- ``OpaquelyEmacsConvertible``
- ``EmacsValue``
- ``PersistentEmacsValue``
- ``Symbol``

### Error handling

- <doc:ErrorHandling>
- ``EmacsError``

### Asynchronous callbacks

- <doc:AsyncCallbacks>
- ``Channel``
- ``Environment/openChannel(name:)``
