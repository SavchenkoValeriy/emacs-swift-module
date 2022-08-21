//
// Call.swift
// Copyright (C) 2022 Valeriy Savchenko
//
// This file is part of EmacsSwiftModule.
//
// EmacsSwiftModule is free software: you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by the Free
// Software Foundation, either version 3 of the License, or (at your option)
// any later version.
//
// EmacsSwiftModule is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
// or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
// more details.
//
// You should have received a copy of the GNU General Public License along with
// EmacsSwiftModule. If not, see <https://www.gnu.org/licenses/>.
//
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
  @discardableResult public func apply(
    _ fun: EmacsValue, with args: [EmacsConvertible]
  ) throws
    -> EmacsValue
  {
    var rawArgs = try args.map { try $0.convert(within: self).raw }
    return EmacsValue(
      from: try check(pointee.funcall(raw, fun.raw, args.count, &rawArgs)))
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
  @discardableResult public func apply(
    _ fun: String, with args: [EmacsConvertible]
  ) throws
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
  @discardableResult public func apply<R: EmacsConvertible>(
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
  @discardableResult public func apply<R: EmacsConvertible>(
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
  @discardableResult public func funcall(
    _ fun: EmacsValue, with args: EmacsConvertible...
  ) throws
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
  @discardableResult public func funcall(
    _ fun: String, with args: EmacsConvertible...
  )
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
  @discardableResult public func funcall<R: EmacsConvertible>(
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
  @discardableResult public func funcall<R: EmacsConvertible>(
    _ fun: String, with args: EmacsConvertible...
  ) throws -> R {
    return try R.convert(from: try apply(fun, with: args), within: self)
  }
}
