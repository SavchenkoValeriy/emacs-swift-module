# Asynchronous Callbacks

Calling Lisp functions without an active Environment.

## Overview

As it was mentioned in <doc:Lifetimes>, ``Environment`` instances could not be stored and captured. Additionally, dynamic modules are not allowed to use given environments from a different thread they were given it on. This can be a problem if we want to use one of the rich Swift APIs to do some useful work for us. We do want to tell the Emacs side that the work was done, and pass in some results. ``Channel`` mechanism was designed specifically with this goal in mind and it provides multiple ways of passing data back into Lisp.

## Creating a Channel

In order to create a ``Channel``, you do need to have an active environment. Simply call ``Environment/openChannel(name:)`` with a name for that channel, and that's pretty much it. You are allowed to create multiple channels and use them simultaneously. Channel callbacks are serialized to be called in exactly the same order their Swift counter-parts got called in the first place. Because of this reason, it might be a good idea to have different channels for less frequent important callbacks and more frequent, but less important callbacks.

## withEnvironment

The easiest way of interacting with ``Environment`` using an open ``Channel`` is via ``Channel/withEnvironment(_:)``. This function allows you to execute some code with Emacs environment whenever we'll get it from Emacs.

```swift
// do some work
channel.withEnvironment {
  env throws in try env.funcall("message", with: "The work is done!")
}
// keep doing something else
```

It should be noted that the code from `// keep doing something else` will most likely get executed before before our message will appear in Emacs. For this reason, `withEnvironment` (and other callbacks) don't have return values.

## callback

In many cases, we want to adapt some asynchronous APIs to Lisp. Let's say we have a UI form that represents a text-field or something similar. When the user submits the form, a callback is called with the user-written text. We probably don't want to do anything with this text on the Swift side, but our module can pass it to the Lisp side. Of course, we can implement it using ``Channel/withEnvironment(_:)``:

```swift
form.onSubmit {
  (text: String) in
  channel.withEnvironment {
    env throws in try env.funcall("lisp-on-submit", with: text)
  }
}
```

Instead of having to closures, we can use one of the `callback` methods.

```swift
form.onSubmit(channel.callback {
  (env: Environment, text: String) throws in
  try env.funcall("lisp-on-submit", with: text)
})
```

This family of methods turns closures that have ``Environment`` as its first parameter into closures that don't. In our example, it's `((Environment, String) -> Void) -> (String) -> Void`.

This way, we can write the code that would've been very similar to the code that doesn't need to communicate with Emacs in the first place. However, sometimes we don't even need to do anything else except for communicating with Lisp.

Let's extend our previous example:

```swift
try env.defun("create-form") {
  (onSubmit: PersistentEmacsValue) in
  let form = new Form()
  form.onSubmit(channel.callback {
    (env: Environment, text: String) throws in
    try env.funcall(onSubmit, with: text)
  })
  return form
}
```

Here, we expose form creation to Lisp in its entirety, and allow users to create it when they want it and have a callback completely on the Lisp side. This code works, but feels a bit wordy. For this reason, ``Channel`` provides a family of methods also named `callback` that work with ``EmacsValue`` functions directly. Let's look at how we can rewrite our code first.

```swift
try env.defun("create-form") {
  (onSubmit: PersistentEmacsValue) in
  let form = new Form()
  form.onSubmit(channel.callback(onSubmit))
  return form
}
```

That's it, we turned `onSubmit` Lisp function into a Swift closure: `(String) -> Void`. You can use this formula with all kinds of closure types, ``Channel`` will create a Swift closure exactly of type that's expected by the API. Of course, since we call into a Lisp function, it means that all arguments should be ``EmacsConvertible`` (see <doc:TypeConversions>).

## hooks

Emacs Lisp has a different way of notifying some code of system-wide events, - hooks. In some cases, it would be the most appropriate tool to use for designing our module's API. ``Channel`` also provides a family of `hook` methods that you can use this way:

```swift
try env.defun("create-form") {
  let form = new Form()
  form.onSubmit(channel.hook("form-submit-hooks"))
  return form
}
```

Essentially, it does the same thing as the `callback` method in the earlier snippet, but it runs a hook instead.
