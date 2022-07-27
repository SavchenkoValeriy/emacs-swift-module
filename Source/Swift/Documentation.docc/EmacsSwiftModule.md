# ``EmacsSwiftModule``

A Swift library to write Emacs plugins in Swift!

## Overview

Emacs Swift module provides a convenient API for writing [dynamic modules for Emacs](https://www.gnu.org/software/emacs/manual/html_node/elisp/Writing-Dynamic-Modules.html) in Swift. It marries a dynamic nature of Emacs Lisp with strong static typization of Swift and hides the roughness of the original C API together with harder aspects of that language such as a lack closures and manual memory management. It also translates Emacs Lisp errors and Swift exceptions into each another .

## Topics

### Environment

- ``Environment``
- ``RuntimePointer``

### Type conversions

- ``EmacsConvertible``
- ``OpaquelyEmacsConvertible``
- ``EmacsValue``
- ``PersistentEmacsValue``
- ``Symbol``

### Error handling

- ``EmacsError``
