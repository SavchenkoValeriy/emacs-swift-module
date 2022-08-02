class LazyHook0: AnyLazyCallback {
  let hook: String
  init(hook: String) {
    self.hook = hook
  }
  func call(_ env: Environment, with args: Any) throws {
    try env.funcall("run-hooks", with: Symbol(name: hook))
  }
}

class LazyHook1<T: EmacsConvertible>: AnyLazyCallback {
  let hook: String
  init(hook: String) {
    self.hook = hook
  }
  func call(_ env: Environment, with args: Any) throws {
    if let arg = args as? T {
      try env.funcall("run-hook-with-args", with: Symbol(name: hook), arg)
    }
  }
}

class LazyHook2<T1: EmacsConvertible, T2: EmacsConvertible>:
  AnyLazyCallback
{
  let hook: String
  init(hook: String) {
    self.hook = hook
  }
  func call(_ env: Environment, with args: Any) throws {
    if let arg = args as? (T1, T2) {
      try env.funcall(
        "run-hook-with-args", with: Symbol(name: hook), arg.0, arg.1)
    }
  }
}

class LazyHook3<
  T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible
>: AnyLazyCallback {
  let hook: String
  init(hook: String) {
    self.hook = hook
  }
  func call(_ env: Environment, with args: Any) throws {
    if let arg = args as? (T1, T2, T3) {
      try env.funcall(
        "run-hook-with-args", with: Symbol(name: hook), arg.0, arg.1, arg.2)
    }
  }
}

class LazyHook4<
  T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible,
  T4: EmacsConvertible
>: AnyLazyCallback {
  let hook: String
  init(hook: String) {
    self.hook = hook
  }
  func call(_ env: Environment, with args: Any) throws {
    if let arg = args as? (T1, T2, T3, T4) {
      try env.funcall(
        "run-hook-with-args", with: Symbol(name: hook), arg.0, arg.1, arg.2,
        arg.3)
    }
  }
}

class LazyHook5<
  T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible,
  T4: EmacsConvertible, T5: EmacsConvertible
>: AnyLazyCallback {
  let hook: String
  init(hook: String) {
    self.hook = hook
  }
  func call(_ env: Environment, with args: Any) throws {
    if let arg = args as? (T1, T2, T3, T4, T5) {
      try env.funcall(
        "run-hook-with-args", with: Symbol(name: hook), arg.0, arg.1, arg.2,
        arg.3, arg.4)
    }
  }
}

extension Channel {
  /// Make a Swift callback out of an Emacs hook's name.
  ///
  /// This allows us to use Emacs hooks as callbacks in Swift APIs.
  /// Please, see <doc:AsyncCallbacks> for more details on that.
  ///
  /// - Parameter function: a name of a Lisp hook to turn into callback.
  /// - Returns: a callback that if called, will eventually run the hook.
  public func hook(_ hook: String)
    -> () -> Void
  {
    return { [self] in
      register(
        callback: LazyHook0(hook: hook), args: ())
    }
  }
  /// Make a Swift callback out of an Emacs hook's name.
  ///
  /// This allows us to use Emacs hooks as callbacks in Swift APIs.
  /// Please, see <doc:AsyncCallbacks> for more details on that.
  ///
  /// - Parameter function: a name of a Lisp hook to turn into callback.
  /// - Returns: a callback that if called, will eventually run the hook.
  public func hook<T: EmacsConvertible>(_ hook: String)
    -> (T) -> Void
  {
    return { [self] arg in
      register(
        callback: LazyHook1<T>(hook: hook), args: arg)
    }
  }
  /// Make a Swift callback out of an Emacs hook's name.
  ///
  /// This allows us to use Emacs hooks as callbacks in Swift APIs.
  /// Please, see <doc:AsyncCallbacks> for more details on that.
  ///
  /// - Parameter function: a name of a Lisp hook to turn into callback.
  /// - Returns: a callback that if called, will eventually run the hook.
  public func hook<T1: EmacsConvertible, T2: EmacsConvertible>(
    _ hook: String
  ) -> (T1, T2) -> Void {
    return { [self] (arg1, arg2) in
      register(
        callback: LazyHook2<T1, T2>(hook: hook),
        args: (arg1, arg2))
    }
  }
  /// Make a Swift callback out of an Emacs hook's name.
  ///
  /// This allows us to use Emacs hooks as callbacks in Swift APIs.
  /// Please, see <doc:AsyncCallbacks> for more details on that.
  ///
  /// - Parameter function: a name of a Lisp hook to turn into callback.
  /// - Returns: a callback that if called, will eventually run the hook.
  public func hook<
    T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible
  >(
    _ hook: String
  ) -> (T1, T2, T3) -> Void {
    return { [self] (arg1, arg2, arg3) in
      register(
        callback: LazyHook3<T1, T2, T3>(hook: hook),
        args: (arg1, arg2, arg3))
    }
  }
  /// Make a Swift callback out of an Emacs hook's name.
  ///
  /// This allows us to use Emacs hooks as callbacks in Swift APIs.
  /// Please, see <doc:AsyncCallbacks> for more details on that.
  ///
  /// - Parameter function: a name of a Lisp hook to turn into callback.
  /// - Returns: a callback that if called, will eventually run the hook.
  public func hook<
    T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible,
    T4: EmacsConvertible
  >(
    _ hook: String
  ) -> (T1, T2, T3, T4) -> Void {
    return { [self] (arg1, arg2, arg3, arg4) in
      register(
        callback: LazyHook4<T1, T2, T3, T4>(hook: hook),
        args: (arg1, arg2, arg3, arg4))
    }
  }
  /// Make a Swift callback out of an Emacs hook's name.
  ///
  /// This allows us to use Emacs hooks as callbacks in Swift APIs.
  /// Please, see <doc:AsyncCallbacks> for more details on that.
  ///
  /// - Parameter function: a name of a Lisp hook to turn into callback.
  /// - Returns: a callback that if called, will eventually run the hook.
  public func hook<
    T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible,
    T4: EmacsConvertible, T5: EmacsConvertible
  >(
    _ hook: String
  ) -> (T1, T2, T3, T4, T5) -> Void {
    return { [self] (arg1, arg2, arg3, arg4, arg5) in
      register(
        callback: LazyHook5<T1, T2, T3, T4, T5>(hook: hook),
        args: (arg1, arg2, arg3, arg4, arg5))
    }
  }
}
