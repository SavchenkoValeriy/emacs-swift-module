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
        .takeUnretainedValue()  // We take unretained value because we probably want to
      // allow users calling the same function multiple times. And this also means that
      // the captured functions will NEVER get retained, even if we decide to redefine this
      // name to be a different function. Unlike user_ptr, Emacs doesn't provide us with a
      // finalizer for function data. Probably, it's not a problem if we won't generate
      // more and more functions.
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
        let result = try impl.function(env, buffer.map { EmacsValue(from: $0) })
        // Since our function returns back `EmacsValue`, we need to unwrap it and
        // pass Emacs a raw pointer it knows about.
        return result.raw

      } catch (EmacsError.wrongType(let expected, let actual, let value)) {
        // For `EmacsError.wrongType` exceptions, we use `wrong-type-argument` since
        // it is an already defined error and it fits us like a glove.
        env.error(
          tag: try! env.intern("wrong-type-argument"), with: expected, actual,
          value)

      } catch (EmacsError.customError(let message)) {
        env.error(with: message)

      } catch (EmacsError.signal(let symbol, let data)) {
        env.signal(symbol, with: data)

      } catch (EmacsError.thrown(let tag, let value)) {
        env.throwForTag(tag, with: value)

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
    let funcValue = EmacsValue(
      from: raw.pointee.make_function(
        raw, function.arity, function.arity, actualFunction, docstring,
        wrappedPtr))
    if let name = name {
      // Create a symbol for it.
      let symbol = try intern(name)
      // And tie them together nicely.
      let _ = try funcall("fset", with: symbol, funcValue)
    }
    return funcValue
  }
}
