# Calling Lisp Functions

Calling Lisp functions from your Swift code.

## `funcall` and `apply`

Similarly to Emacs Lisp functions `funcall` and `apply`, ``Environment`` provides methods with the same names with similar semantics. In 99% of the cases you'll need `funcall`, which accepts a function to call and whatever arguments you pass with it. Every function has a structure.

```swift
env.funcall("lisp-function", with: 42, 36.6, true, "String", [10, 20, 30])
```

As you can see, it accepts and properly converts native Swift types and values into their Lisp counterparts.
If something goes wrong on the Emacs side, this call will throw ``EmacsError``. This can represent any error you usually see in Emacs, `void-function` for missing function with that name, or `wrong-type-argument`, etc.

The only difference `apply` function has over `funcall` is that it accepts an array of all of the call arguments as its second argument. So, it can be of use if you construct your arguments list in runtime.

By default, `funcall` and `apply` return an opaque ``EmacsValue`` (see <doc:TypeConversions>) that represents some dynamically typed Lisp value. All of the values under the hood are ``EmacsValue``. However, both of these functions have a bit of generic magic to it, and if the return type should be something different and it is clear from the context, the environment will try to convert it for you.

Let's consider the following example:
```swift
let result = try env.funcall("format", with "%S: %S", 42, "42")
```

This will produce ``EmacsValue``, but if we change it to either
```swift
let result1: String = try env.funcall("format", with "%S: %S", 42, "42")
let result2 = try env.funcall("format", with "%S: %S", 42, "42") as String
acceptsString(try env.funcall("format", with "%S: %S", 42, "42"))
```
it will get correctly converted into Swift's own `String`.
