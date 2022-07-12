import EmacsModule

extension Environment {
  //
  // FUNCALL variants
  //
  public func funcall(_ fun: EmacsValue, with args: [EmacsConvertible]) throws
    -> EmacsValue
  {
    var rawArgs = try args.map { try $0.convert(within: self).raw }
    return EmacsValue(
      from: try check(raw.pointee.funcall(raw, fun.raw, args.count, &rawArgs)))
  }
  public func funcall(_ fun: EmacsValue, with args: EmacsConvertible...) throws
    -> EmacsValue
  {
    return try funcall(fun, with: args)
  }
  public func funcall(_ fun: String, with args: [EmacsConvertible])
    throws -> EmacsValue
  {
    return try funcall(try intern(fun), with: args)
  }
  public func funcall(_ fun: String, with args: EmacsConvertible...)
    throws -> EmacsValue
  {
    return try funcall(fun, with: args as [EmacsConvertible])
  }
}
