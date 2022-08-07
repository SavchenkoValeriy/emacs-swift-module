# Type conversions

Converting Swift values into Lisp values and vice versa.

## Static vs Dynamic Types

Emacs Lisp is a dynamically typed language meaning that every Lisp variable or symbol can potentially carry a value of any type. Passing a value of a some type into a function that doesn't expect that type causes a runtime error. Swift, on the other hand is statically typed. The power of statically-typed languages comes from harder guarantees that the compiler enforces onto the language users.

When we define a Lisp function in Swift using Swift types, we actually express runtime expectations that we have about the calls to this new function. The users are still able to write this code with incorrect arguments and they will know that they actually make a mistake only when they execute their code. At the same time, `EmacsSwiftModule` guarantees that when you specify a Swift type for either a parameter or a call result, you'll get a valid object of that type or an exception will be thrown.

## Opaque Dynamic Values

Underneath, at Emacs level, all values are typed as ``EmacsValue``. And as it was mentioned in <doc:DefiningLispFunctions>, the module developer can request to process value of that type instead of specifying any of the Swift types. Actually, the developer can even use a mixture of static and dynamic types in their code by using types like `[EmacsValue]` that will represent a Swift array of opaque Lisp values.

Each ``EmacsValue`` is tied to the ``Environment`` it comes from. This fact might cause some surprising effects if the value outlives its environment. See <doc:Lifetimes> to understand it in full, and learn about `EmacsSwiftModule` mechanisms to make it easier for you.

## EmacsConvertible Protocol

`EmacsSwiftModule` defines ``EmacsConvertible`` protocol that describes how each of the conforming types converts into ``EmacsValue`` and from it. It is important to understand that each conversion should always involve a valid ``Environment`` object.

You can manually do conversions with all of the conforming types as in the following example

```swift
let value = try "Hello Lisp".convert(within: env)
let string = try String.convert(from: value, within: env)
assert(string == "Hello Lisp")
```

As seen in this example, conversion functions ``EmacsConvertible/convert(within:)`` and ``EmacsConvertible/convert(from:within:)``, and they are all you need to turn your type into ``EmacsConvertible``.

## Opaque Conversion

In many cases, you might want to share one of your reference type objects with the Lisp side, but as identity, not as a source of data. Let's look at a simple example, I want my Swift API to allow Lisp users to create and delete buttons. And let's say that underneath we want to use some `FancyUI.Button` class. We came up with a code like this, which seems very reasonable.

```swift
try env.defun("button-create") {
  (text: String) in FancyUI.Button(text)
}
try env.defun("button-delete") {
  (button: FancyUI.Button) in button.delete()
}
```

But `FancyUI.Button` doesn't conform to ``EmacsConvertible``, and it's hard to think of some good encoding to make it work. Swift has its own memory management, we don't want to screw it up. Plus `FancyUI.Button` is not our class to begin with, it's pretty hard to find things that uniquely identify it. What is left is low-level APIs, but don't we want to avoid it by using Swift in the first place!?

That's absolutely right, and that's why `EmacsSwiftModule` defines ``OpaquelyEmacsConvertible``. The protocol that comes with the default implementation. It converts any given class into an opaque Lisp object. Similarly to how ``EmacsValue`` is a black box in Swift, and how we can communicate with it only through ``Environment``, such opaque objects are black boxes in Lisp and make sense only together with your APIs. ``OpaquelyEmacsConvertible`` makes sure to marry Swift's reference counters and Emacs' garbage collection to avoid any surprises.

This being said, you can add the following piece to your code:
```swift
extension FancyUI.Button: OpaquelyEmacsConvertible {}
```
and the code above will work as expected.

## Currently-supported Type Conversions

 - Swift `Int` into/from Lisp `integer`
 - Swift `Double` into/from Lisp `float`
 - Swift `Bool` into Lisp as `t/nil`. When converting from Lisp, any value but `nil` is considered to be `true`. `Bool` is the only native type that doesn't throw during conversion.
 - Swift `Optional` if the underlying type is ``EmacsConvertible``. Swift `nil` into/from Lisp `nil`, and other cases match the underlying type conversion.
 - Swift `Array` if the element type is ``EmacsConvertible``, into/from Lisp `vector` (not `list`). Maybe one day, we'll decide to support `list` conversions as well, but one-to-many conversion can get pretty tricky and `vector` seems like a better match.
 - Swift `Dictionary` if the key and value types are both ``EmacsConvertible``, into/from Lisp `alist`.
 - ``Symbol`` into/from Lisp `symbol`
 - ``ConsCell`` into/from Lisp `cons`
 - ``List`` into/from Lisp `list`
