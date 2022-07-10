import EmacsModule

extension Environment {
  //
  // FUNCALL variants
  //
  public func funcall(_ fun: EmacsValue, with args: [EmacsValue]) -> EmacsValue
  {
    var rawArgs = args.map { $0.raw }
    return EmacsValue(
      from: raw.pointee.funcall(raw, fun.raw, args.count, &rawArgs))
  }
  public func funcall(_ fun: EmacsValue, with args: EmacsValue...) -> EmacsValue
  {
    return funcall(fun, with: args)
  }
  public func funcall(_ fun: EmacsValue, with args: [EmacsConvertible])
    -> EmacsValue
  {
    return funcall(fun, with: args.map { $0.convert(within: self) })
  }
  public func funcall(_ fun: EmacsValue, with args: EmacsConvertible...)
    -> EmacsValue
  {
    return funcall(fun, with: args)
  }
  public func funcall(_ fun: String, with args: [EmacsValue]) -> EmacsValue {
    return funcall(intern(fun), with: args)
  }
  public func funcall(_ fun: String, with args: EmacsValue...) -> EmacsValue {
    return funcall(fun, with: args)
  }
  public func funcall(_ fun: String, with args: [EmacsConvertible])
    -> EmacsValue
  {
    return funcall(fun, with: args.map { $0.convert(within: self) })
  }
  public func funcall(_ fun: String, with args: EmacsConvertible...)
    -> EmacsValue
  {
    return funcall(fun, with: args)
  }
}
