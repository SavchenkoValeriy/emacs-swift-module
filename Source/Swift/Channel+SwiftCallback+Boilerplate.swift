class LazySwiftCallback0: AnyLazyCallback {
  let function: (Environment) throws -> Void
  init(function: @escaping (Environment) throws -> Void) {
    self.function = function
  }
  func call(_ env: Environment, with args: Any) throws {
    try function(env)
  }
}

class LazySwiftCallback1<T>: AnyLazyCallback {
  let function: (Environment, T) throws -> Void
  init(function: @escaping (Environment, T) throws -> Void) {
    self.function = function
  }
  func call(_ env: Environment, with args: Any) throws {
    if let arg = args as? T {
      try function(env, arg)
    }
  }
}

class LazySwiftCallback2<T1, T2>: AnyLazyCallback {
  let function: (Environment, T1, T2) throws -> Void
  init(function: @escaping (Environment, T1, T2) throws -> Void) {
    self.function = function
  }
  func call(_ env: Environment, with args: Any) throws {
    if let arg = args as? (T1, T2) {
      try function(env, arg.0, arg.1)
    }
  }
}

class LazySwiftCallback3<T1, T2, T3>: AnyLazyCallback {
  let function: (Environment, T1, T2, T3) throws -> Void
  init(function: @escaping (Environment, T1, T2, T3) throws -> Void) {
    self.function = function
  }
  func call(_ env: Environment, with args: Any) throws {
    if let arg = args as? (T1, T2, T3) {
      try function(env, arg.0, arg.1, arg.2)
    }
  }
}

class LazySwiftCallback4<T1, T2, T3, T4>: AnyLazyCallback {
  let function: (Environment, T1, T2, T3, T4) throws -> Void
  init(function: @escaping (Environment, T1, T2, T3, T4) throws -> Void) {
    self.function = function
  }
  func call(_ env: Environment, with args: Any) throws {
    if let arg = args as? (T1, T2, T3, T4) {
      try function(env, arg.0, arg.1, arg.2, arg.3)
    }
  }
}

class LazySwiftCallback5<T1, T2, T3, T4, T5>: AnyLazyCallback {
  let function: (Environment, T1, T2, T3, T4, T5) throws -> Void
  init(function: @escaping (Environment, T1, T2, T3, T4, T5) throws -> Void) {
    self.function = function
  }
  func call(_ env: Environment, with args: Any) throws {
    if let arg = args as? (T1, T2, T3, T4, T5) {
      try function(env, arg.0, arg.1, arg.2, arg.3, arg.4)
    }
  }
}

extension Channel {
  public func callback(function: @escaping (Environment) throws -> Void)
    -> () -> Void
  {
    return { [self] in
      let index = stack.push(
        callback: LazySwiftCallback0(function: function), args: ())
      write(index)
    }
  }
  public func callback<T>(function: @escaping (Environment, T) throws -> Void)
    -> (T) -> Void
  {
    return { [self] arg in
      let index = stack.push(
        callback: LazySwiftCallback1(function: function), args: arg)
      write(index)
    }
  }
  public func callback<T1, T2>(
    function: @escaping (Environment, T1, T2) throws -> Void
  ) -> (T1, T2) -> Void {
    return { [self] (arg1, arg2) in
      let index = stack.push(
        callback: LazySwiftCallback2(function: function), args: (arg1, arg2))
      write(index)
    }
  }
  public func callback<T1, T2, T3>(
    function: @escaping (Environment, T1, T2, T3) throws -> Void
  ) -> (T1, T2, T3) -> Void {
    return { [self] (arg1, arg2, arg3) in
      let index = stack.push(
        callback: LazySwiftCallback3(function: function),
        args: (arg1, arg2, arg3))
      write(index)
    }
  }
  public func callback<T1, T2, T3, T4>(
    function: @escaping (Environment, T1, T2, T3, T4) throws -> Void
  ) -> (T1, T2, T3, T4) -> Void {
    return { [self] (arg1, arg2, arg3, arg4) in
      let index = stack.push(
        callback: LazySwiftCallback4(function: function),
        args: (arg1, arg2, arg3, arg4))
      write(index)
    }
  }
  public func callback<T1, T2, T3, T4, T5>(
    function: @escaping (Environment, T1, T2, T3, T4, T5) throws -> Void
  ) -> (T1, T2, T3, T4, T5) -> Void {
    return { [self] (arg1, arg2, arg3, arg4, arg5) in
      let index = stack.push(
        callback: LazySwiftCallback5(function: function),
        args: (arg1, arg2, arg3, arg4, arg5))
      write(index)
    }
  }
}
