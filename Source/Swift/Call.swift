import EmacsModule

extension Environment {
  /// Call Emacs Lisp function by its symbol or value.
  ///
  /// It replicates the `apply` Emacs Lisp function by asking you to provide
  /// all arguments in one array. The main difference between `funcall` and `apply`
  /// is that if you pass an array of values to `funcall` it will be considered
  /// as one argument, and if you pass it to `apply` it will be treated as a list
  /// of separate arguments.
  ///
  /// - Parameters:
  ///   - fun: the symbol naming the function or the function value itself.
  ///   - args: an array of arguments for the call.
  /// - Returns: an opaque Emacs value representing the result of the call.
  /// - Throws: an instance of `EmacsError` if something went wrong on the Emacs side.
  public func apply(_ fun: EmacsValue, with args: [EmacsConvertible]) throws
    -> EmacsValue
  {
    var rawArgs = try args.map { try $0.convert(within: self).raw }
    return EmacsValue(
      from: try check(raw.pointee.funcall(raw, fun.raw, args.count, &rawArgs)))
  }
  /// Call Emacs Lisp function by its name.
  ///
  /// It replicates the `apply` Emacs Lisp function by asking you to provide
  /// all arguments in one array. The main difference between `funcall` and `apply`
  /// is that if you pass an array of values to `funcall` it will be considered
  /// as one argument, and if you pass it to `apply` it will be treated as a list
  /// of separate arguments.
  ///
  /// - Parameters:
  ///   - fun: the name of the function to call.
  ///   - args: an array of arguments for the call.
  /// - Returns: an opaque Emacs value representing the result of the call.
  /// - Throws: an instance of `EmacsError` if something went wrong on the Emacs side.
  public func apply(_ fun: String, with args: [EmacsConvertible]) throws
    -> EmacsValue
  {
    return try apply(try intern(fun), with: args)
  }
  /// Call Emacs Lisp function by its symbol or value.
  ///
  /// It replicates the `apply` Emacs Lisp function by asking you to provide
  /// all arguments in one array. The main difference between `funcall` and `apply`
  /// is that if you pass an array of values to `funcall` it will be considered
  /// as one argument, and if you pass it to `apply` it will be treated as a list
  /// of separate arguments.
  ///
  /// - Parameters:
  ///   - fun: the name of the function to call.
  ///   - args: an array of arguments for the call.
  /// - Returns: a value of the type inferred from the context.
  /// - Throws: an instance of `EmacsError` if something went wrong on the Emacs side
  /// or the value has incorrect type.
  public func apply<R: EmacsConvertible>(
    _ fun: EmacsValue, with args: [EmacsConvertible]
  ) throws -> R {
    return try R.convert(from: try apply(fun, with: args), within: self)
  }
  /// Call Emacs Lisp function by its name.
  ///
  /// It replicates the `apply` Emacs Lisp function by asking you to provide
  /// all arguments in one array. The main difference between `funcall` and `apply`
  /// is that if you pass an array of values to `funcall` it will be considered
  /// as one argument, and if you pass it to `apply` it will be treated as a list
  /// of separate arguments.
  ///
  /// - Parameters:
  ///   - fun: the name of the function to call.
  ///   - args: an array of arguments for the call.
  /// - Returns: a value of the type inferred from the context.
  /// - Throws: an instance of `EmacsError` if something went wrong on the Emacs side
  /// or the value has incorrect type.
  public func apply<R: EmacsConvertible>(
    _ fun: String, with args: [EmacsConvertible]
  ) throws -> R {
    return try R.convert(from: try apply(fun, with: args), within: self)
  }
  /// Call Emacs Lisp function by its symbol or value.
  ///
  /// It replicates the `funcall` Emacs Lisp function by asking you to provide
  /// all arguments separately. The main difference between `funcall` and `apply`
  /// is that if you pass an array of values to `funcall` it will be considered
  /// as one argument, and if you pass it to `apply` it will be treated as a list
  /// of separate arguments.
  ///
  /// - Parameters:
  ///   - fun: the symbol naming the function or the function value itself.
  ///   - args: the arguments for the call.
  /// - Returns: an opaque Emacs value representing the result of the call.
  /// - Throws: an instance of `EmacsError` if something went wrong on the Emacs side.
  public func funcall(_ fun: EmacsValue, with args: EmacsConvertible...) throws
    -> EmacsValue
  {
    return try apply(fun, with: args)
  }
  /// Call Emacs Lisp function by its name.
  ///
  /// It replicates the `funcall` Emacs Lisp function by asking you to provide
  /// all arguments separately. The main difference between `funcall` and `apply`
  /// is that if you pass an array of values to `funcall` it will be considered
  /// as one argument, and if you pass it to `apply` it will be treated as a list
  /// of separate arguments.
  ///
  /// - Parameters:
  ///   - fun: the name of the function to call.
  ///   - args: the arguments for the call.
  /// - Returns: an opaque Emacs value representing the result of the call.
  /// - Throws: an instance of `EmacsError` if something went wrong on the Emacs side.
  public func funcall(_ fun: String, with args: EmacsConvertible...)
    throws -> EmacsValue
  {
    return try apply(fun, with: args)
  }
  /// Call Emacs Lisp function by its symbol or value.
  ///
  /// It replicates the `funcall` Emacs Lisp function by asking you to provide
  /// all arguments separately. The main difference between `funcall` and `apply`
  /// is that if you pass an array of values to `funcall` it will be considered
  /// as one argument, and if you pass it to `apply` it will be treated as a list
  /// of separate arguments.
  ///
  /// - Parameters:
  ///   - fun: the name of the function to call.
  ///   - args: the arguments for the call.
  /// - Returns: a value of the type inferred from the context.
  /// - Throws: an instance of `EmacsError` if something went wrong on the Emacs side
  /// or the value has incorrect type.
  public func funcall<R: EmacsConvertible>(
    _ fun: EmacsValue, with args: EmacsConvertible...
  ) throws -> R {
    return try R.convert(from: try apply(fun, with: args), within: self)
  }
  /// Call Emacs Lisp function by its name.
  ///
  /// It replicates the `funcall` Emacs Lisp function by asking you to provide
  /// all arguments separately. The main difference between `funcall` and `apply`
  /// is that if you pass an array of values to `funcall` it will be considered
  /// as one argument, and if you pass it to `apply` it will be treated as a list
  /// of separate arguments.
  ///
  /// - Parameters:
  ///   - fun: the name of the function to call.
  ///   - args: the arguments for the call.
  /// - Returns: a value of the type inferred from the context.
  /// - Throws: an instance of `EmacsError` if something went wrong on the Emacs side
  /// or the value has incorrect type.
  public func funcall<R: EmacsConvertible>(
    _ fun: String, with args: EmacsConvertible...
  ) throws -> R {
    return try R.convert(from: try apply(fun, with: args), within: self)
  }
}
