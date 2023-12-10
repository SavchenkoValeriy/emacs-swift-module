# Lifetimes

Emacs internals lifetimes.

## Environment Lifetime

Environment lives as long as the function it was given to executes. This covers both module initialization and Lisp functions defined in Swift. Using environment outside of its lifetime will most likely crash Emacs. You can think of ``Environment`` to be always an unowned reference.

This means that storing ``Environment`` as part of some state, or capturing it in a closure that will be used afterwards is not going to work. The most typical problem looks somwehat like this:
```swift
try env.defun("test") {
  // some code before
  try env.funcall("lisp-function")
  // some code after
}
```
When the function does a lot of things, it's hard to spot the fact that we are actually using the wrong environment. We captured the one from the outer scope, and using it here will cause Emacs to crash. Instead, we can explicitly ask for a new instance of ``Environment`` in every Swift-defined Lisp function.
```swift
try env.defun("test") {
  (env: Environment) in
  // some code before
  try env.funcall("lisp-function")
  // some code after
}
```
This code doesn't change the number of required arguments to call `test`, Emacs already passes a new environment with every function invocation. This way we just ask ``Environment`` to pass it to us on call.

This lifetime restriction ensures one of the core principles of Emacs dynamic modules **"Emacs calls into then module's code when it wants to, not the other way around"**. Using ``Environment`` outside of its lifetime means calling into Emacs asynchronously when Emacs does not expect it to happen. That will violate its concurrency model.

In order to ensure this requirement, ``Environment`` has additional checks in place to spot lifetime violations and throw ``EmacsError/lifetimeViolation`` exception when it does. This way the very first snippet from this section won't actually crash Emacs, but simply signal an error when calling the `test` function.

## EmacsValue Lifetime

Similarly to ``Environment``, opaque ``EmacsValue`` also has a limited lifetime. It is not enforced as strictly, and can produce even more confusion.

Essentially every ``EmacsValue`` is bound to the ``Environment`` instance that produced it. This means that ``EmacsValue`` has *the same lifetime* as its ``Environment``. In the most probable scenario, you produce a value and use it with the same environment. Nothing to worry about in this case!
```swift
let value = try env.funcall("foo")
try env.funcall("bar", with: value)
```

The problem comes when you want to keep certain value and share it between two environments.
```swift
var stash: EmacsValue = env.Nil
try env.defun("stash-arg") {
  (arg: EmacsValue) in stash = arg
}
try env.defun("get-stash") {
  stash
}
```
It should not work because of the lifetimes violation, but in most cases it does. On my machine, this code works as the user expected it to work. However, if we modify it a little bit, we can receive some very confusing results.

```swift
var stash = [EmacsValue]()
try env.defun("stash-arg") {
  (arg: EmacsValue) in stash.append(arg)
}
try env.defun("get-stash") {
  stash
}
```
Looks very much the same, we keep all the arguments instead of the last one. So, what would be the problem?
```emacs-lisp
(stash-arg 1)
(stash-arg 2)
(stash-arg 3)
(get-stash) ;; => [3 3 3]
```
It returns a vector of `3`s! The size is right, the last value is right, but the whole vector shares the same value. It is especially strange after the previous example. The reason is the lifetime of `arg`, in this situation it is not enforced. However, Emacs reuses the same memory to store a new argument value every time. It is just an implementation detail of Emacs that we discovered accidentally. We should *never* rely on such undocumented features. They can change from one release to another, and behave differently on different platforms.

Instead, we should use ``PersistentEmacsValue``.
```swift
var stash = [EmacsValue]()
try env.defun("stash-arg") {
  (arg: PersistentEmacsValue) in stash.append(arg)
}
try env.defun("get-stash") {
  stash
}
```
This fixes it! We just changed parameter type of our function and that's enough! This way we tell `EmacsSwiftModule` that actually the Swift side should take care of this value's lifetime. ``PersistentEmacsValue`` effectively marries Swift's ARC and Emacs' garbage collection, so we can share values across environments.

``PersistentEmacsValue`` also works with `funcall` and `apply` result type inference, so you can write:
```swift
let x: PersistentEmacsValue = try env.funcall("foo")
let y = try env.funcall("bar") as PersistentEmacsValue
```

If you already have ``EmacsValue``, you can turn it into ``PersistentEmacsValue`` by calling ``Environment/preserve(_:)``.
```swift
let lambda = try env.preserve(env.defun {
  // do some cool stuff
})
```
After preservation, `lambda` can be safely used from different functions.

> Info: ``Environment`` also provides ``Environment/retain(_:)`` and ``Environment/release(_:)`` low-level APIs for manual reference-counting. But ``PersistentEmacsValue`` and ``Environment/preserve(_:)`` should be preferred to avoid mistakes.

## Concurrency

As it was mentioned earlier, ``Environment`` lifetime restriction comes from the desire to keep Emacs own concurrency model intact. This also includes another rule for using ``Environment`` - it should be used on the same thread it was created on. It is important to keep it mind, even considering that using ``Environment`` asynchronously will most likely violate its lifetime. To learn how to mix asynchronous code with Emacs interactions, please refer to <doc:AsyncCallbacks>.

Similarly to lifetime violations, ``Environment`` validates that its user follows Emacs concurrency model and throws ``EmacsError/threadModelViolation`` when ``Environment`` is attempted to be used on the other thread.
