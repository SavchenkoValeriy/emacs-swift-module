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
