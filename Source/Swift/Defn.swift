import EmacsModule

private class DefnImplementation {
  let function: (Environment, [EmacsValue]) -> EmacsValue
  let arity: Int
  init<T: EmacsConvertible, R: EmacsConvertible>(_ original: @escaping (T) -> R)
  {
    function = { (env, args) in
      original(T.convert(from: args[0], within: env)).convert(within: env)
    }
    arity = 1
  }
  init<T: EmacsConvertible, R: EmacsConvertible>(
    _ original: @escaping (Environment, T) -> R
  ) {
    function = { (env, args) in
      original(env, T.convert(from: args[0], within: env)).convert(within: env)
    }
    arity = 1
  }

  init<T1: EmacsConvertible, T2: EmacsConvertible, R: EmacsConvertible>(
    _ original: @escaping (T1, T2) -> R
  ) {
    function = { (env, args) in
      original(
        T1.convert(from: args[0], within: env),
        T2.convert(from: args[0], within: env)
      ).convert(within: env)
    }
    arity = 2
  }
  init<T1: EmacsConvertible, T2: EmacsConvertible, R: EmacsConvertible>(
    _ original: @escaping (Environment, T1, T2) -> R
  ) {
    function = { (env, args) in
      original(
        env, T1.convert(from: args[0], within: env),
        T2.convert(from: args[0], within: env)
      ).convert(within: env)
    }
    arity = 2
  }

  init<
    T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible,
    R: EmacsConvertible
  >(_ original: @escaping (T1, T2, T3) -> R) {
    function = { (env, args) in
      original(
        T1.convert(from: args[0], within: env),
        T2.convert(from: args[0], within: env),
        T3.convert(from: args[0], within: env)
      ).convert(within: env)
    }
    arity = 3
  }
  init<
    T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible,
    R: EmacsConvertible
  >(_ original: @escaping (Environment, T1, T2, T3) -> R) {
    function = { (env, args) in
      original(
        env, T1.convert(from: args[0], within: env),
        T2.convert(from: args[0], within: env),
        T3.convert(from: args[0], within: env)
      ).convert(within: env)
    }
    arity = 3
  }

  init<
    T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible,
    T4: EmacsConvertible, R: EmacsConvertible
  >(_ original: @escaping (T1, T2, T3, T4) -> R) {
    function = { (env, args) in
      original(
        T1.convert(from: args[0], within: env),
        T2.convert(from: args[0], within: env),
        T3.convert(from: args[0], within: env),
        T4.convert(from: args[0], within: env)
      ).convert(within: env)
    }
    arity = 4
  }
  init<
    T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible,
    T4: EmacsConvertible, R: EmacsConvertible
  >(_ original: @escaping (Environment, T1, T2, T3, T4) -> R) {
    function = { (env, args) in
      original(
        env, T1.convert(from: args[0], within: env),
        T2.convert(from: args[0], within: env),
        T3.convert(from: args[0], within: env),
        T4.convert(from: args[0], within: env)
      ).convert(within: env)
    }
    arity = 4
  }

  init<
    T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible,
    T4: EmacsConvertible, T5: EmacsConvertible, R: EmacsConvertible
  >(_ original: @escaping (T1, T2, T3, T4, T5) -> R) {
    function = { (env, args) in
      original(
        T1.convert(from: args[0], within: env),
        T2.convert(from: args[0], within: env),
        T3.convert(from: args[0], within: env),
        T4.convert(from: args[0], within: env),
        T5.convert(from: args[0], within: env)
      ).convert(within: env)
    }
    arity = 5
  }
  init<
    T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible,
    T4: EmacsConvertible, T5: EmacsConvertible, R: EmacsConvertible
  >(_ original: @escaping (Environment, T1, T2, T3, T4, T5) -> R) {
    function = { (env, args) in
      original(
        env, T1.convert(from: args[0], within: env),
        T2.convert(from: args[0], within: env),
        T3.convert(from: args[0], within: env),
        T4.convert(from: args[0], within: env),
        T5.convert(from: args[0], within: env)
      ).convert(within: env)
    }
    arity = 5
  }
}

extension Environment {
  //
  // Make function
  //
  public func defn<
    T: EmacsConvertible,
    R: EmacsConvertible
  >(
    named name: String,
    with docstring: String = "",
    function: @escaping (T) -> R
  ) {
    let wrapped = DefnImplementation(function)
    defn(named: name, with: docstring, function: wrapped)
  }
  public func defn<
    T: EmacsConvertible,
    R: EmacsConvertible
  >(
    named name: String,
    with docstring: String = "",
    function: @escaping (Environment, T) -> R
  ) {
    let wrapped = DefnImplementation(function)
    defn(named: name, with: docstring, function: wrapped)
  }

  public func defn<
    T1: EmacsConvertible,
    T2: EmacsConvertible,
    R: EmacsConvertible
  >(
    named name: String,
    with docstring: String = "",
    function: @escaping (T1, T2) -> R
  ) {
    let wrapped = DefnImplementation(function)
    defn(named: name, with: docstring, function: wrapped)
  }
  public func defn<
    T1: EmacsConvertible,
    T2: EmacsConvertible,
    R: EmacsConvertible
  >(
    named name: String,
    with docstring: String = "",
    function: @escaping (Environment, T1, T2) -> R
  ) {
    let wrapped = DefnImplementation(function)
    defn(named: name, with: docstring, function: wrapped)
  }

  public func defn<
    T1: EmacsConvertible,
    T2: EmacsConvertible,
    T3: EmacsConvertible,
    R: EmacsConvertible
  >(
    named name: String,
    with docstring: String = "",
    function: @escaping (T1, T2, T3) -> R
  ) {
    let wrapped = DefnImplementation(function)
    defn(named: name, with: docstring, function: wrapped)
  }
  public func defn<
    T1: EmacsConvertible,
    T2: EmacsConvertible,
    T3: EmacsConvertible,
    R: EmacsConvertible
  >(
    named name: String,
    with docstring: String = "",
    function: @escaping (Environment, T1, T2, T3) -> R
  ) {
    let wrapped = DefnImplementation(function)
    defn(named: name, with: docstring, function: wrapped)
  }

  public func defn<
    T1: EmacsConvertible,
    T2: EmacsConvertible,
    T3: EmacsConvertible,
    T4: EmacsConvertible,
    R: EmacsConvertible
  >(
    named name: String,
    with docstring: String = "",
    function: @escaping (T1, T2, T3, T4) -> R
  ) {
    let wrapped = DefnImplementation(function)
    defn(named: name, with: docstring, function: wrapped)
  }
  public func defn<
    T1: EmacsConvertible,
    T2: EmacsConvertible,
    T3: EmacsConvertible,
    T4: EmacsConvertible,
    R: EmacsConvertible
  >(
    named name: String,
    with docstring: String = "",
    function: @escaping (Environment, T1, T2, T3, T4) -> R
  ) {
    let wrapped = DefnImplementation(function)
    defn(named: name, with: docstring, function: wrapped)
  }

  public func defn<
    T1: EmacsConvertible,
    T2: EmacsConvertible,
    T3: EmacsConvertible,
    T4: EmacsConvertible,
    T5: EmacsConvertible,
    R: EmacsConvertible
  >(
    named name: String,
    with docstring: String = "",
    function: @escaping (T1, T2, T3, T4, T5) -> R
  ) {
    let wrapped = DefnImplementation(function)
    defn(named: name, with: docstring, function: wrapped)
  }
  public func defn<
    T1: EmacsConvertible,
    T2: EmacsConvertible,
    T3: EmacsConvertible,
    T4: EmacsConvertible,
    T5: EmacsConvertible,
    R: EmacsConvertible
  >(
    named name: String,
    with docstring: String = "",
    function: @escaping (Environment, T1, T2, T3, T4, T5) -> R
  ) {
    let wrapped = DefnImplementation(function)
    defn(named: name, with: docstring, function: wrapped)
  }

  private func defn(
    named name: String,
    with docstring: String,
    function: DefnImplementation
  ) {
    let actualFunction: RawFunctionType = { rawEnv, num, args, data in
      let env = Environment(from: rawEnv!)
      let arg = EmacsValue(from: args?.pointee)
      let impl = Unmanaged<DefnImplementation>.fromOpaque(data!)
        .takeUnretainedValue()
      let result = impl.function(env, [arg])
      return result.raw
    }
    let wrappedPtr = Unmanaged.passRetained(function).toOpaque()
    let funcValue = EmacsValue(
      from: raw.pointee.make_function(
        raw, function.arity, function.arity, actualFunction, docstring,
        wrappedPtr))
    let symbol = intern(name)
    let _ = funcall("fset", with: symbol, funcValue)
  }
}
