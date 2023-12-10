//
// Defun.swift
// Copyright (C) 2022 Valeriy Savchenko
//
// This file is part of EmacsSwiftModule.
//
// EmacsSwiftModule is free software: you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by the Free
// Software Foundation, either version 3 of the License, or (at your option)
// any later version.
//
// EmacsSwiftModule is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
// or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
// more details.
//
// You should have received a copy of the GNU General Public License along with
// EmacsSwiftModule. If not, see <https://www.gnu.org/licenses/>.
//
import EmacsModule

/// It is a helper function to change the signature of the given
/// closure from (T1, T2, ...) -> R type into (Environment, [EmacsValue]) -> EmacsValue,
/// which is way easier to handle uniformly.
///
/// Arity goes up to 5 and includes the following function signatures matrix:
///    * returning Void or some EmacsConvertible
///    * accepting or not accepting additional Environment argument
///
/// This means that each function of arities 0 to 5 has 4 variants making it
/// 24 initializers in total. It's a lot of boilerplate that will keep growing
/// if we won't come up with some sort of solution here. Either code generation,
/// or Swift compiler for variadic templates or/and non-nominal types extensions.
final class DefunImplementation {
  let function: (Environment, [EmacsValue]) throws -> EmacsValue
  let arity: Int

  init(
    _ function: @escaping (Environment, [EmacsValue]) throws -> EmacsValue,
    _ arity: Int
  ) {
    self.function = function
    self.arity = arity
  }
}

extension Environment {
  /// The actual implementation of `defun`.
  ///
  /// This function accepts a name, a docstring, and a wrapped Swift closure
  /// and declares an Emacs Lisp function out of it.
  @discardableResult func defun(
    named name: String?,
    with docstring: String,
    function: DefunImplementation
  ) throws -> EmacsValue {
    // It's yet another function that wraps the user provided implementation,
    // but this time it accepts everything Emacs expects it to accept.
    //
    // Additionally, it conforms to everything you need to be in order to convert
    // to a pure C function pointer. One should understand that ALL Swift-declared
    // functions share this implementation. Not even different copies of it, just
    // one copy of the same thing.
    //
    // The main trick with how we can pull it off is the last parameter of this
    // function. In C, it is a plain `void *` where you can put anything you wish.
    // And this is where each function's Swift implementation will be coming from.
    let actualFunction: RawFunctionType = { rawEnv, num, args, data in
      // Wrap environment with a Swift convenience wrapper
      let env = Environment(from: rawEnv!)
      // Bundle `args` pointer and the `num` argument into one sized buffer.
      // Now we can iterate over it like it is a regular container of `emacs_value?>.
      let buffer = UnsafeBufferPointer<emacs_value?>(start: args, count: num)
      // Cast data to `DefunImplementation`. Please note, that it is crucial for us
      // not even capturing generic types in this callback. That's why `DefunImplementation`
      // has a very simple interface to it.
      let impl = Unmanaged<DefunImplementation>.fromOpaque(data!)
        .takeUnretainedValue() // We take unretained value because we probably want to
      // allow users calling the same function multiple times. We only clean it up in
      // a function's finalizer (see below).
      assert(
        num == impl.arity,
        "Emacs Lisp shouldn't've allowed a call with a wrong number of arguments!"
      )
      // This function should never ever throw. When it throws, Emacs crashes.
      // That's why we need to catch anything coming from the Swift side and surface
      // it properly on the Emacs side.
      do {
        // And here's the last step, call `DefunImplementation` with the given
        // environment and a list of arguments appropriately wrapped in `EmacsValue`.
        let result = try impl.function(
          env, buffer.map { EmacsValue(from: $0) }
        )
        defer { env.invalidate() }
        // Since our function returns back `EmacsValue`, we need to unwrap it and
        // pass Emacs a raw pointer it knows about.
        return result.raw

      } catch let EmacsError.wrongType(expected, actual, value) {
        // For `EmacsError.wrongType` exceptions, we use `wrong-type-argument` since
        // it is an already defined error and it fits us like a glove.
        env.error(
          tag: try! env.intern("wrong-type-argument"), with: expected, actual,
          value
        )

      } catch let EmacsError.customError(message) {
        env.error(with: message)

      } catch let EmacsError.signal(symbol, data) {
        env.signal(symbol, with: data)

      } catch let EmacsError.thrown(tag, value) {
        env.throwForTag(tag, with: value)

      } catch EmacsError.interrupted {
        // do nothing, just return

      } catch {
        // As mentioned earlier, we cannot let any of the Swift exceptions to get
        // away or it'll crash Emacs.
        env.error(with: "Swift exception: \(error)")
      }

      // We still need to return something even if we had an error. Emacs will most likely
      // ignore this value, but `nil` still seems appropriate.
      return env.Nil.raw
    }
    // And here is how we turn our `DefunImplementation` into a `void *` that can
    // be thought of as a function's context or persistent data.
    let wrappedPtr = Unmanaged.passRetained(function).toOpaque()
    // Here we create the anonymous function that carries our implementation.
    let env = try pointee
    let funcValue = EmacsValue(
      from: env.make_function(
        raw, function.arity, function.arity, actualFunction, docstring,
        wrappedPtr
      ))

    // Only starting from Emacs 28 there are finalizers for functions.
    // For earlier versions, we have to live with the fact that there is
    // no way to garbage collect them.
    if version >= .Emacs28 {
      // When the function value is garbage collected, we also
      // need to cleanup on our side. Function `data` pointer keeps alive
      // quite a large chunk of data (nested closures and their captures).
      env.set_function_finalizer(raw, funcValue.raw) {
        (data: RawOpaquePointer?) in
        Unmanaged<DefunImplementation>.fromOpaque(data!).release()
      }
    }

    if let name {
      // Create a symbol for it.
      let symbol = try intern(name)
      // And tie them together nicely.
      _ = try funcall("fset", with: symbol, funcValue)
    }
    return funcValue
  }
}
