import EmacsModule

extension Environment {
  //
  // FUNCALL variants
  //
  public func funcall(_ fun: EmacsValue, with args: [EmacsValue]) throws
    -> EmacsValue
  {
    var rawArgs = args.map { $0.raw }
    return EmacsValue(
      from: raw.pointee.funcall(raw, fun.raw, args.count, &rawArgs))
  }
  public func funcall(_ fun: EmacsValue, with args: EmacsValue...) throws
    -> EmacsValue
  {
    return try funcall(fun, with: args)
  }
  public func funcall(_ fun: EmacsValue, with args: [EmacsConvertible])
    throws -> EmacsValue
  {
    return try funcall(fun, with: args.map { try $0.convert(within: self) })
  }
  public func funcall(_ fun: EmacsValue, with args: EmacsConvertible...)
    throws -> EmacsValue
  {
    return try funcall(fun, with: args)
  }
  public func funcall(_ fun: String, with args: [EmacsValue]) throws
    -> EmacsValue
  {
    return try funcall(intern(fun), with: args)
  }
  public func funcall(_ fun: String, with args: EmacsValue...) throws
    -> EmacsValue
  {
    return try funcall(fun, with: args)
  }
  public func funcall(_ fun: String, with args: [EmacsConvertible])
    throws -> EmacsValue
  {
    return try funcall(fun, with: args.map { try $0.convert(within: self) })
  }
  public func funcall(_ fun: String, with args: EmacsConvertible...)
    throws -> EmacsValue
  {
    return try funcall(fun, with: args)
  }
}
