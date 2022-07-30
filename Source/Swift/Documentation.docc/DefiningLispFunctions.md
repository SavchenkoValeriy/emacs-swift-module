# Defining Lisp Functions

Defining Emacs Lisp functions directly from Swift.

## defun

``Environment`` provides many overloads of the `defun` method allowing you to convert Swift functions to Lisp functions.
All the variants take 3 arguments:
  - optional name for a new function (`nil` for lambda)
  - docstring (empty by default)
  - function implementation as a Swift closure

It returns an opaque ``EmacsValue`` that can be called via `funcall` or `apply` (mostly useful for lambda functions).
If something goes wrong on the Emacs side, it can throw ``EmacsError``, however, it is much less likely compared to calls.

Let's start with this simple example to see how it works:
```swift
env.defun("swift-+") { (lhs: Int, rhs: Int) -> Int in lhs + rhs }
```

This will define a Lisp function named `swift-+` taking exactly two arguments. You can call it like any other Lisp function.
```emacs-lisp
(swift-+ 1 1) ;; => 2
```

If you pass not integers as arguments, you get `wrong-type-argument` like with any other Lisp function expecting certain types from its arguments.

You can use any type that is convertible to Lisp (see <doc:TypeConversions>) as your closure argument/return types to get this sweet automatic conversion.

## Acquiring the Environment

Our `swift-+` function is nice, but we don't communicate with Emacs internals in it, while in the majority of cases we'd want to call a thing or two from the Lisp side. Since our code is a closure, we might have a temptation to simply capture the ``Environment`` variable and use it. DON'T DO THAT. See more on the reasons in <doc:Lifetimes>, but for now just remember to add it as a parameter into your closure.

```swift
env.defun("swift-+") {
  (env: Environment, lhs: Int, rhs: Int) throws -> Int in
  try env.funcall("+", with: lhs, rhs)
}
```

This new version still can be called exactly the same way, but now it calls a Lisp function itself.

> Important: Don't capture environment in your function's body. If you need it, add it as a first parameter of your closure.

## Using Opaque Values

Sometimes we don't want to use a fancy conversion in our function and we simply want to forward our dynamically typed argument to another Lisp function. This is totally valid and we can use ``EmacsValue`` directly in our function's signature.

```swift
env.defun("to-string") {
  (env: Environment, value: EmacsValue) throws -> String in
  try env.funcall("format", with: "%S", value)
}
```

This function takes an opaque value and forwards it to another function. We re-throw any exceptions coming from that call, so if that function has some type expectation for it's argument, the user still gets notified about it.

> Important: Opaque values have very specific lifetime rules to them. Please, check <doc:Lifetimes> for more detail.
