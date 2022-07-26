class LazyLispCallback0: AnyLazyCallback {
  let function: EmacsValue
  init(function: EmacsValue) {
    self.function = function
  }
  func call(_ env: Environment, with args: Any) throws {
    try env.funcall(function)
  }
}

class LazyLispCallback1<T: EmacsConvertible>: AnyLazyCallback {
  let function: EmacsValue
  init(function: EmacsValue) {
    self.function = function
  }
  func call(_ env: Environment, with args: Any) throws {
    if let arg = args as? T {
      try env.funcall(function, with: arg)
    }
  }
}

class LazyLispCallback2<T1: EmacsConvertible, T2: EmacsConvertible>:
  AnyLazyCallback
{
  let function: EmacsValue
  init(function: EmacsValue) {
    self.function = function
  }
  func call(_ env: Environment, with args: Any) throws {
    if let arg = args as? (T1, T2) {
      try env.funcall(function, with: arg.0, arg.1)
    }
  }
}

class LazyLispCallback3<
  T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible
>: AnyLazyCallback {
  let function: EmacsValue
  init(function: EmacsValue) {
    self.function = function
  }
  func call(_ env: Environment, with args: Any) throws {
    if let arg = args as? (T1, T2, T3) {
      try env.funcall(function, with: arg.0, arg.1, arg.2)
    }
  }
}

class LazyLispCallback4<
  T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible,
  T4: EmacsConvertible
>: AnyLazyCallback {
  let function: EmacsValue
  init(function: EmacsValue) {
    self.function = function
  }
  func call(_ env: Environment, with args: Any) throws {
    if let arg = args as? (T1, T2, T3, T4) {
      try env.funcall(function, with: arg.0, arg.1, arg.2, arg.3)
    }
  }
}

class LazyLispCallback5<
  T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible,
  T4: EmacsConvertible, T5: EmacsConvertible
>: AnyLazyCallback {
  let function: EmacsValue
  init(function: EmacsValue) {
    self.function = function
  }
  func call(_ env: Environment, with args: Any) throws {
    if let arg = args as? (T1, T2, T3, T4, T5) {
      try env.funcall(function, with: arg.0, arg.1, arg.2, arg.3, arg.4)
    }
  }
}

extension Channel {
  public func callback(_ function: EmacsValue)
    -> () -> Void
  {
    return { [self] in
      register(
        callback: LazyLispCallback0(function: function), args: ())
    }
  }
  public func callback<T: EmacsConvertible>(_ function: EmacsValue)
    -> (T) -> Void
  {
    return { [self] arg in
      register(
        callback: LazyLispCallback1<T>(function: function), args: arg)
    }
  }
  public func callback<T1: EmacsConvertible, T2: EmacsConvertible>(
    _ function: EmacsValue
  ) -> (T1, T2) -> Void {
    return { [self] (arg1, arg2) in
      register(
        callback: LazyLispCallback2<T1, T2>(function: function),
        args: (arg1, arg2))
    }
  }
  public func callback<
    T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible
  >(
    _ function: EmacsValue
  ) -> (T1, T2, T3) -> Void {
    return { [self] (arg1, arg2, arg3) in
      register(
        callback: LazyLispCallback3<T1, T2, T3>(function: function),
        args: (arg1, arg2, arg3))
    }
  }
  public func callback<
    T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible,
    T4: EmacsConvertible
  >(
    _ function: EmacsValue
  ) -> (T1, T2, T3, T4) -> Void {
    return { [self] (arg1, arg2, arg3, arg4) in
      register(
        callback: LazyLispCallback4<T1, T2, T3, T4>(function: function),
        args: (arg1, arg2, arg3, arg4))
    }
  }
  public func callback<
    T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible,
    T4: EmacsConvertible, T5: EmacsConvertible
  >(
    _ function: EmacsValue
  ) -> (T1, T2, T3, T4, T5) -> Void {
    return { [self] (arg1, arg2, arg3, arg4, arg5) in
      register(
        callback: LazyLispCallback5<T1, T2, T3, T4, T5>(function: function),
        args: (arg1, arg2, arg3, arg4, arg5))
    }
  }
}
