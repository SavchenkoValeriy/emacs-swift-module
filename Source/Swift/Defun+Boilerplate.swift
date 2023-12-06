//
// Defun+Boilerplate.swift
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
extension DefunImplementation {
  #if swift(>=5.9)
  convenience init<R: EmacsConvertible, each T: EmacsConvertible>(_ original: @escaping (repeat each T) throws -> R) {
    self.init(
      { (env, args) in
        let index = counter()
        return try original(
          repeat (each T).convert(from: args[index()], within: env)
        ).convert(within: env)
      }, count(repeat (each T).self))
  }

  convenience init<each T: EmacsConvertible>(_ original: @escaping (repeat each T) throws -> Void) {
    self.init(
      { (env, args) in
        let index = counter()
        try original(
          repeat (each T).convert(from: args[index()], within: env)
        )
        return env.Nil
      }, count(repeat (each T).self))
  }

  convenience init<R: EmacsConvertible, each T: EmacsConvertible>(_ original: @escaping (Environment, repeat each T) throws -> R) {
    self.init(
      { (env, args) in
        let index = counter()
        return try original(
          env, repeat (each T).convert(from: args[index()], within: env)
        ).convert(within: env)
      }, count(repeat (each T).self))
  }

  convenience init<each T: EmacsConvertible>(_ original: @escaping (Environment, repeat each T) throws -> Void) {
    self.init(
      { (env, args) in
        let index = counter()
        try original(
          env, repeat (each T).convert(from: args[index()], within: env)
        )
        return env.Nil
      }, count(repeat (each T).self))
  }
  #else
  convenience init<R: EmacsConvertible>(_ original: @escaping () throws -> R) {
    self.init(
      { (env, args) in
        try original().convert(within: env)
      }, 0)
  }
  convenience init<R: EmacsConvertible>(
    _ original: @escaping (Environment) throws -> R
  ) {
    self.init(
      { (env, args) in
        try original(env).convert(within: env)
      }, 0)
  }
  convenience init(_ original: @escaping () throws -> Void) {
    self.init(
      { (env, args) in
        try original()
        return env.Nil
      }, 0)
  }
  convenience init(
    _ original: @escaping (Environment) throws -> Void
  ) {
    self.init(
      { (env, args) in
        try original(env)
        return env.Nil
      }, 0)
  }

  convenience init<T: EmacsConvertible, R: EmacsConvertible>(
    _ original: @escaping (T) throws -> R
  ) {
    self.init(
      { (env, args) in
        try original(T.convert(from: args[0], within: env)).convert(within: env)
      }, 1)
  }
  convenience init<T: EmacsConvertible, R: EmacsConvertible>(
    _ original: @escaping (Environment, T) throws -> R
  ) {
    self.init(
      { (env, args) in
        try original(env, T.convert(from: args[0], within: env)).convert(
          within: env)
      }, 1)
  }
  convenience init<T: EmacsConvertible>(
    _ original: @escaping (T) throws -> Void
  ) {
    self.init(
      { (env, args) in
        try original(T.convert(from: args[0], within: env))
        return env.Nil
      }, 1)
  }
  convenience init<T: EmacsConvertible>(
    _ original: @escaping (Environment, T) throws -> Void
  ) {
    self.init(
      { (env, args) in
        try original(env, T.convert(from: args[0], within: env))
        return env.Nil
      }, 1)
  }

  convenience init<
    T1: EmacsConvertible, T2: EmacsConvertible, R: EmacsConvertible
  >(
    _ original: @escaping (T1, T2) throws -> R
  ) {
    self.init(
      { (env, args) in
        try original(
          T1.convert(from: args[0], within: env),
          T2.convert(from: args[1], within: env)
        ).convert(within: env)
      }, 2)
  }
  convenience init<
    T1: EmacsConvertible, T2: EmacsConvertible, R: EmacsConvertible
  >(
    _ original: @escaping (Environment, T1, T2) throws -> R
  ) {
    self.init(
      { (env, args) in
        try original(
          env, T1.convert(from: args[0], within: env),
          T2.convert(from: args[1], within: env)
        ).convert(within: env)
      }, 2)
  }
  convenience init<T1: EmacsConvertible, T2: EmacsConvertible>(
    _ original: @escaping (T1, T2) throws -> Void
  ) {
    self.init(
      { (env, args) in
        try original(
          T1.convert(from: args[0], within: env),
          T2.convert(from: args[1], within: env)
        )
        return env.Nil
      }, 2)
  }
  convenience init<T1: EmacsConvertible, T2: EmacsConvertible>(
    _ original: @escaping (Environment, T1, T2) throws -> Void
  ) {
    self.init(
      { (env, args) in
        try original(
          env, T1.convert(from: args[0], within: env),
          T2.convert(from: args[1], within: env)
        )
        return env.Nil
      }, 2)
  }

  convenience init<
    T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible,
    R: EmacsConvertible
  >(_ original: @escaping (T1, T2, T3) throws -> R) {
    self.init(
      { (env, args) in
        try original(
          T1.convert(from: args[0], within: env),
          T2.convert(from: args[1], within: env),
          T3.convert(from: args[2], within: env)
        ).convert(within: env)
      }, 3)
  }
  convenience init<
    T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible,
    R: EmacsConvertible
  >(_ original: @escaping (Environment, T1, T2, T3) throws -> R) {
    self.init(
      { (env, args) in
        try original(
          env, T1.convert(from: args[0], within: env),
          T2.convert(from: args[1], within: env),
          T3.convert(from: args[2], within: env)
        ).convert(within: env)
      }, 3)
  }
  convenience init<
    T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible
  >(_ original: @escaping (T1, T2, T3) throws -> Void) {
    self.init(
      { (env, args) in
        try original(
          T1.convert(from: args[0], within: env),
          T2.convert(from: args[1], within: env),
          T3.convert(from: args[2], within: env)
        )
        return env.Nil
      }, 3)
  }
  convenience init<
    T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible
  >(_ original: @escaping (Environment, T1, T2, T3) throws -> Void) {
    self.init(
      { (env, args) in
        try original(
          env, T1.convert(from: args[0], within: env),
          T2.convert(from: args[1], within: env),
          T3.convert(from: args[2], within: env)
        )
        return env.Nil
      }, 3)
  }

  convenience init<
    T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible,
    T4: EmacsConvertible, R: EmacsConvertible
  >(_ original: @escaping (T1, T2, T3, T4) throws -> R) {
    self.init(
      { (env, args) in
        try original(
          T1.convert(from: args[0], within: env),
          T2.convert(from: args[1], within: env),
          T3.convert(from: args[2], within: env),
          T4.convert(from: args[3], within: env)
        ).convert(within: env)
      }, 4)
  }
  convenience init<
    T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible,
    T4: EmacsConvertible, R: EmacsConvertible
  >(_ original: @escaping (Environment, T1, T2, T3, T4) throws -> R) {
    self.init(
      { (env, args) in
        try original(
          env, T1.convert(from: args[0], within: env),
          T2.convert(from: args[1], within: env),
          T3.convert(from: args[2], within: env),
          T4.convert(from: args[3], within: env)
        ).convert(within: env)
      }, 4)
  }
  convenience init<
    T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible,
    T4: EmacsConvertible
  >(_ original: @escaping (T1, T2, T3, T4) throws -> Void) {
    self.init(
      { (env, args) in
        try original(
          T1.convert(from: args[0], within: env),
          T2.convert(from: args[1], within: env),
          T3.convert(from: args[2], within: env),
          T4.convert(from: args[3], within: env)
        )
        return env.Nil
      }, 4)
  }
  convenience init<
    T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible,
    T4: EmacsConvertible
  >(_ original: @escaping (Environment, T1, T2, T3, T4) throws -> Void) {
    self.init(
      { (env, args) in
        try original(
          env, T1.convert(from: args[0], within: env),
          T2.convert(from: args[1], within: env),
          T3.convert(from: args[2], within: env),
          T4.convert(from: args[3], within: env)
        )
        return env.Nil
      }, 4)
  }

  convenience init<
    T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible,
    T4: EmacsConvertible, T5: EmacsConvertible, R: EmacsConvertible
  >(_ original: @escaping (T1, T2, T3, T4, T5) throws -> R) {
    self.init(
      { (env, args) in
        try original(
          T1.convert(from: args[0], within: env),
          T2.convert(from: args[1], within: env),
          T3.convert(from: args[2], within: env),
          T4.convert(from: args[3], within: env),
          T5.convert(from: args[4], within: env)
        ).convert(within: env)
      }, 5)
  }
  convenience init<
    T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible,
    T4: EmacsConvertible, T5: EmacsConvertible, R: EmacsConvertible
  >(_ original: @escaping (Environment, T1, T2, T3, T4, T5) throws -> R) {
    self.init(
      { (env, args) in
        try original(
          env, T1.convert(from: args[0], within: env),
          T2.convert(from: args[1], within: env),
          T3.convert(from: args[2], within: env),
          T4.convert(from: args[3], within: env),
          T5.convert(from: args[4], within: env)
        ).convert(within: env)
      }, 5)
  }
  convenience init<
    T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible,
    T4: EmacsConvertible, T5: EmacsConvertible
  >(_ original: @escaping (T1, T2, T3, T4, T5) throws -> Void) {
    self.init(
      { (env, args) in
        try original(
          T1.convert(from: args[0], within: env),
          T2.convert(from: args[1], within: env),
          T3.convert(from: args[2], within: env),
          T4.convert(from: args[3], within: env),
          T5.convert(from: args[4], within: env)
        )
        return env.Nil
      }, 5)
  }
  convenience init<
    T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible,
    T4: EmacsConvertible, T5: EmacsConvertible
  >(_ original: @escaping (Environment, T1, T2, T3, T4, T5) throws -> Void) {
    self.init(
      { (env, args) in
        try original(
          env, T1.convert(from: args[0], within: env),
          T2.convert(from: args[1], within: env),
          T3.convert(from: args[2], within: env),
          T4.convert(from: args[3], within: env),
          T5.convert(from: args[4], within: env)
        )
        return env.Nil
      }, 5)
  }
  #endif
}

extension Environment {
  #if swift(>=5.9)
  @discardableResult
  public func defun<
    R: EmacsConvertible,
    each T: EmacsConvertible
  >(
    _ name: String? = nil,
    with docstring: String = "",
    function: @escaping (repeat each T) throws -> R
  ) throws -> EmacsValue {
    let wrapped = DefunImplementation(function)
    return try defun(named: name, with: docstring, function: wrapped)
  }
  @discardableResult
  public func defun<
    each T: EmacsConvertible
  >(
    _ name: String? = nil,
    with docstring: String = "",
    function: @escaping (repeat each T) throws -> Void
  ) throws -> EmacsValue {
    let wrapped = DefunImplementation(function)
    return try defun(named: name, with: docstring, function: wrapped)
  }
  @discardableResult
  public func defun<
    R: EmacsConvertible,
    each T: EmacsConvertible
  >(
    _ name: String? = nil,
    with docstring: String = "",
    function: @escaping (Environment, repeat each T) throws -> R
  ) throws -> EmacsValue {
    let wrapped = DefunImplementation(function)
    return try defun(named: name, with: docstring, function: wrapped)
  }
  @discardableResult
  public func defun<
    each T: EmacsConvertible
  >(
    _ name: String? = nil,
    with docstring: String = "",
    function: @escaping (Environment, repeat each T) throws -> Void
  ) throws -> EmacsValue {
    let wrapped = DefunImplementation(function)
    return try defun(named: name, with: docstring, function: wrapped)
  }
  #else
  /// Define a Lisp function without parameters out of the given closure.
  ///
  ///  - Parameters:
  ///    - name: the name of a new function, can be `nil` for lambda functions
  ///    - with: the docstring for the new function
  ///    - function: the actual Swift implementation of a new function
  ///
  ///  - Returns: a new function as ``EmacsValue`` that can be called via `funcall` or `apply`.
  ///
  ///  - Throws: ``EmacsError`` if something goes wrong on the Emacs side.
  ///
  /// See <doc:DefiningLispFunctions> for examples.
  @discardableResult
  public func defun<
    R: EmacsConvertible
  >(
    _ name: String? = nil,
    with docstring: String = "",
    function: @escaping () throws -> R
  ) throws -> EmacsValue {
    let wrapped = DefunImplementation(function)
    return try defun(named: name, with: docstring, function: wrapped)
  }
  /// Define a Lisp function without parameters out of the given closure.
  ///
  ///  - Parameters:
  ///    - name: the name of a new function, can be `nil` for lambda functions
  ///    - with: the docstring for the new function
  ///    - function: the actual Swift implementation of a new function
  ///
  ///  - Returns: a new function as ``EmacsValue`` that can be called via `funcall` or `apply`.
  ///
  ///  - Throws: ``EmacsError`` if something goes wrong on the Emacs side.
  ///
  /// See <doc:DefiningLispFunctions> for examples.
  @discardableResult
  public func defun<
    R: EmacsConvertible
  >(
    _ name: String? = nil,
    with docstring: String = "",
    function: @escaping (Environment) throws -> R
  ) throws -> EmacsValue {
    let wrapped = DefunImplementation(function)
    return try defun(named: name, with: docstring, function: wrapped)
  }
  /// Define a Lisp function without parameters out of the given closure.
  ///
  ///  - Parameters:
  ///    - name: the name of a new function, can be `nil` for lambda functions
  ///    - with: the docstring for the new function
  ///    - function: the actual Swift implementation of a new function
  ///
  ///  - Returns: a new function as ``EmacsValue`` that can be called via `funcall` or `apply`.
  ///
  ///  - Throws: ``EmacsError`` if something goes wrong on the Emacs side.
  ///
  /// See <doc:DefiningLispFunctions> for examples.
  @discardableResult public func defun(
    _ name: String? = nil,
    with docstring: String = "",
    function: @escaping () throws -> Void
  ) throws -> EmacsValue {
    let wrapped = DefunImplementation(function)
    return try defun(named: name, with: docstring, function: wrapped)
  }
  /// Define a Lisp function without parameters out of the given closure.
  ///
  ///  - Parameters:
  ///    - name: the name of a new function, can be `nil` for lambda functions
  ///    - with: the docstring for the new function
  ///    - function: the actual Swift implementation of a new function
  ///
  ///  - Returns: a new function as ``EmacsValue`` that can be called via `funcall` or `apply`.
  ///
  ///  - Throws: ``EmacsError`` if something goes wrong on the Emacs side.
  ///
  /// See <doc:DefiningLispFunctions> for examples.
  @discardableResult public func defun(
    _ name: String? = nil,
    with docstring: String = "",
    function: @escaping (Environment) throws -> Void
  ) throws -> EmacsValue {
    let wrapped = DefunImplementation(function)
    return try defun(named: name, with: docstring, function: wrapped)
  }

  /// Define a Lisp function with one parameter out of the given closure.
  ///
  ///  - Parameters:
  ///    - name: the name of a new function, can be `nil` for lambda functions
  ///    - with: the docstring for the new function
  ///    - function: the actual Swift implementation of a new function
  ///
  ///  - Returns: a new function as ``EmacsValue`` that can be called via `funcall` or `apply`.
  ///
  ///  - Throws: ``EmacsError`` if something goes wrong on the Emacs side.
  ///
  /// See <doc:DefiningLispFunctions> for examples.
  @discardableResult
  public func defun<
    T: EmacsConvertible,
    R: EmacsConvertible
  >(
    _ name: String? = nil,
    with docstring: String = "",
    function: @escaping (T) throws -> R
  ) throws -> EmacsValue {
    let wrapped = DefunImplementation(function)
    return try defun(named: name, with: docstring, function: wrapped)
  }
  /// Define a Lisp function with one parameter out of the given closure.
  ///
  ///  - Parameters:
  ///    - name: the name of a new function, can be `nil` for lambda functions
  ///    - with: the docstring for the new function
  ///    - function: the actual Swift implementation of a new function
  ///
  ///  - Returns: a new function as ``EmacsValue`` that can be called via `funcall` or `apply`.
  ///
  ///  - Throws: ``EmacsError`` if something goes wrong on the Emacs side.
  ///
  /// See <doc:DefiningLispFunctions> for examples.
  @discardableResult
  public func defun<
    T: EmacsConvertible,
    R: EmacsConvertible
  >(
    _ name: String? = nil,
    with docstring: String = "",
    function: @escaping (Environment, T) throws -> R
  ) throws -> EmacsValue {
    let wrapped = DefunImplementation(function)
    return try defun(named: name, with: docstring, function: wrapped)
  }
  /// Define a Lisp function with one parameter out of the given closure.
  ///
  ///  - Parameters:
  ///    - name: the name of a new function, can be `nil` for lambda functions
  ///    - with: the docstring for the new function
  ///    - function: the actual Swift implementation of a new function
  ///
  ///  - Returns: a new function as ``EmacsValue`` that can be called via `funcall` or `apply`.
  ///
  ///  - Throws: ``EmacsError`` if something goes wrong on the Emacs side.
  ///
  /// See <doc:DefiningLispFunctions> for examples.
  @discardableResult
  public func defun<
    T: EmacsConvertible
  >(
    _ name: String? = nil,
    with docstring: String = "",
    function: @escaping (T) throws -> Void
  ) throws -> EmacsValue {
    let wrapped = DefunImplementation(function)
    return try defun(named: name, with: docstring, function: wrapped)
  }
  /// Define a Lisp function with one parameter out of the given closure.
  ///
  ///  - Parameters:
  ///    - name: the name of a new function, can be `nil` for lambda functions
  ///    - with: the docstring for the new function
  ///    - function: the actual Swift implementation of a new function
  ///
  ///  - Returns: a new function as ``EmacsValue`` that can be called via `funcall` or `apply`.
  ///
  ///  - Throws: ``EmacsError`` if something goes wrong on the Emacs side.
  ///
  /// See <doc:DefiningLispFunctions> for examples.
  @discardableResult
  public func defun<
    T: EmacsConvertible
  >(
    _ name: String? = nil,
    with docstring: String = "",
    function: @escaping (Environment, T) throws -> Void
  ) throws -> EmacsValue {
    let wrapped = DefunImplementation(function)
    return try defun(named: name, with: docstring, function: wrapped)
  }

  /// Define a Lisp function with two parameters out of the given closure.
  ///
  ///  - Parameters:
  ///    - name: the name of a new function, can be `nil` for lambda functions
  ///    - with: the docstring for the new function
  ///    - function: the actual Swift implementation of a new function
  ///
  ///  - Returns: a new function as ``EmacsValue`` that can be called via `funcall` or `apply`.
  ///
  ///  - Throws: ``EmacsError`` if something goes wrong on the Emacs side.
  ///
  /// See <doc:DefiningLispFunctions> for examples.
  @discardableResult
  public func defun<
    T1: EmacsConvertible,
    T2: EmacsConvertible,
    R: EmacsConvertible
  >(
    _ name: String? = nil,
    with docstring: String = "",
    function: @escaping (T1, T2) throws -> R
  ) throws -> EmacsValue {
    let wrapped = DefunImplementation(function)
    return try defun(named: name, with: docstring, function: wrapped)
  }
  /// Define a Lisp function with two parameters out of the given closure.
  ///
  ///  - Parameters:
  ///    - name: the name of a new function, can be `nil` for lambda functions
  ///    - with: the docstring for the new function
  ///    - function: the actual Swift implementation of a new function
  ///
  ///  - Returns: a new function as ``EmacsValue`` that can be called via `funcall` or `apply`.
  ///
  ///  - Throws: ``EmacsError`` if something goes wrong on the Emacs side.
  ///
  /// See <doc:DefiningLispFunctions> for examples.
  @discardableResult
  public func defun<
    T1: EmacsConvertible,
    T2: EmacsConvertible,
    R: EmacsConvertible
  >(
    _ name: String? = nil,
    with docstring: String = "",
    function: @escaping (Environment, T1, T2) throws -> R
  ) throws -> EmacsValue {
    let wrapped = DefunImplementation(function)
    return try defun(named: name, with: docstring, function: wrapped)
  }
  /// Define a Lisp function with two parameters out of the given closure.
  ///
  ///  - Parameters:
  ///    - name: the name of a new function, can be `nil` for lambda functions
  ///    - with: the docstring for the new function
  ///    - function: the actual Swift implementation of a new function
  ///
  ///  - Returns: a new function as ``EmacsValue`` that can be called via `funcall` or `apply`.
  ///
  ///  - Throws: ``EmacsError`` if something goes wrong on the Emacs side.
  ///
  /// See <doc:DefiningLispFunctions> for examples.
  @discardableResult
  public func defun<
    T1: EmacsConvertible,
    T2: EmacsConvertible
  >(
    _ name: String? = nil,
    with docstring: String = "",
    function: @escaping (T1, T2) throws -> Void
  ) throws -> EmacsValue {
    let wrapped = DefunImplementation(function)
    return try defun(named: name, with: docstring, function: wrapped)
  }
  /// Define a Lisp function with two parameters out of the given closure.
  ///
  ///  - Parameters:
  ///    - name: the name of a new function, can be `nil` for lambda functions
  ///    - with: the docstring for the new function
  ///    - function: the actual Swift implementation of a new function
  ///
  ///  - Returns: a new function as ``EmacsValue`` that can be called via `funcall` or `apply`.
  ///
  ///  - Throws: ``EmacsError`` if something goes wrong on the Emacs side.
  ///
  /// See <doc:DefiningLispFunctions> for examples.
  @discardableResult
  public func defun<
    T1: EmacsConvertible,
    T2: EmacsConvertible
  >(
    _ name: String? = nil,
    with docstring: String = "",
    function: @escaping (Environment, T1, T2) throws -> Void
  ) throws -> EmacsValue {
    let wrapped = DefunImplementation(function)
    return try defun(named: name, with: docstring, function: wrapped)
  }

  /// Define a Lisp function with three parameters out of the given closure.
  ///
  ///  - Parameters:
  ///    - name: the name of a new function, can be `nil` for lambda functions
  ///    - with: the docstring for the new function
  ///    - function: the actual Swift implementation of a new function
  ///
  ///  - Returns: a new function as ``EmacsValue`` that can be called via `funcall` or `apply`.
  ///
  ///  - Throws: ``EmacsError`` if something goes wrong on the Emacs side.
  ///
  /// See <doc:DefiningLispFunctions> for examples.
  @discardableResult
  public func defun<
    T1: EmacsConvertible,
    T2: EmacsConvertible,
    T3: EmacsConvertible,
    R: EmacsConvertible
  >(
    _ name: String? = nil,
    with docstring: String = "",
    function: @escaping (T1, T2, T3) throws -> R
  ) throws -> EmacsValue {
    let wrapped = DefunImplementation(function)
    return try defun(named: name, with: docstring, function: wrapped)
  }
  /// Define a Lisp function with three parameters out of the given closure.
  ///
  ///  - Parameters:
  ///    - name: the name of a new function, can be `nil` for lambda functions
  ///    - with: the docstring for the new function
  ///    - function: the actual Swift implementation of a new function
  ///
  ///  - Returns: a new function as ``EmacsValue`` that can be called via `funcall` or `apply`.
  ///
  ///  - Throws: ``EmacsError`` if something goes wrong on the Emacs side.
  ///
  /// See <doc:DefiningLispFunctions> for examples.
  @discardableResult
  public func defun<
    T1: EmacsConvertible,
    T2: EmacsConvertible,
    T3: EmacsConvertible,
    R: EmacsConvertible
  >(
    _ name: String? = nil,
    with docstring: String = "",
    function: @escaping (Environment, T1, T2, T3) throws -> R
  ) throws -> EmacsValue {
    let wrapped = DefunImplementation(function)
    return try defun(named: name, with: docstring, function: wrapped)
  }
  /// Define a Lisp function with three parameters out of the given closure.
  ///
  ///  - Parameters:
  ///    - name: the name of a new function, can be `nil` for lambda functions
  ///    - with: the docstring for the new function
  ///    - function: the actual Swift implementation of a new function
  ///
  ///  - Returns: a new function as ``EmacsValue`` that can be called via `funcall` or `apply`.
  ///
  ///  - Throws: ``EmacsError`` if something goes wrong on the Emacs side.
  ///
  /// See <doc:DefiningLispFunctions> for examples.
  @discardableResult
  public func defun<
    T1: EmacsConvertible,
    T2: EmacsConvertible,
    T3: EmacsConvertible
  >(
    _ name: String? = nil,
    with docstring: String = "",
    function: @escaping (T1, T2, T3) throws -> Void
  ) throws -> EmacsValue {
    let wrapped = DefunImplementation(function)
    return try defun(named: name, with: docstring, function: wrapped)
  }
  /// Define a Lisp function with three parameters out of the given closure.
  ///
  ///  - Parameters:
  ///    - name: the name of a new function, can be `nil` for lambda functions
  ///    - with: the docstring for the new function
  ///    - function: the actual Swift implementation of a new function
  ///
  ///  - Returns: a new function as ``EmacsValue`` that can be called via `funcall` or `apply`.
  ///
  ///  - Throws: ``EmacsError`` if something goes wrong on the Emacs side.
  ///
  /// See <doc:DefiningLispFunctions> for examples.
  @discardableResult
  public func defun<
    T1: EmacsConvertible,
    T2: EmacsConvertible,
    T3: EmacsConvertible
  >(
    _ name: String? = nil,
    with docstring: String = "",
    function: @escaping (Environment, T1, T2, T3) throws -> Void
  ) throws -> EmacsValue {
    let wrapped = DefunImplementation(function)
    return try defun(named: name, with: docstring, function: wrapped)
  }

  /// Define a Lisp function with four parameters out of the given closure.
  ///
  ///  - Parameters:
  ///    - name: the name of a new function, can be `nil` for lambda functions
  ///    - with: the docstring for the new function
  ///    - function: the actual Swift implementation of a new function
  ///
  ///  - Returns: a new function as ``EmacsValue`` that can be called via `funcall` or `apply`.
  ///
  ///  - Throws: ``EmacsError`` if something goes wrong on the Emacs side.
  ///
  /// See <doc:DefiningLispFunctions> for examples.
  @discardableResult
  public func defun<
    T1: EmacsConvertible,
    T2: EmacsConvertible,
    T3: EmacsConvertible,
    T4: EmacsConvertible,
    R: EmacsConvertible
  >(
    _ name: String? = nil,
    with docstring: String = "",
    function: @escaping (T1, T2, T3, T4) throws -> R
  ) throws -> EmacsValue {
    let wrapped = DefunImplementation(function)
    return try defun(named: name, with: docstring, function: wrapped)
  }
  /// Define a Lisp function with four parameters out of the given closure.
  ///
  ///  - Parameters:
  ///    - name: the name of a new function, can be `nil` for lambda functions
  ///    - with: the docstring for the new function
  ///    - function: the actual Swift implementation of a new function
  ///
  ///  - Returns: a new function as ``EmacsValue`` that can be called via `funcall` or `apply`.
  ///
  ///  - Throws: ``EmacsError`` if something goes wrong on the Emacs side.
  ///
  /// See <doc:DefiningLispFunctions> for examples.
  @discardableResult
  public func defun<
    T1: EmacsConvertible,
    T2: EmacsConvertible,
    T3: EmacsConvertible,
    T4: EmacsConvertible,
    R: EmacsConvertible
  >(
    _ name: String? = nil,
    with docstring: String = "",
    function: @escaping (Environment, T1, T2, T3, T4) throws -> R
  ) throws -> EmacsValue {
    let wrapped = DefunImplementation(function)
    return try defun(named: name, with: docstring, function: wrapped)
  }
  /// Define a Lisp function with four parameters out of the given closure.
  ///
  ///  - Parameters:
  ///    - name: the name of a new function, can be `nil` for lambda functions
  ///    - with: the docstring for the new function
  ///    - function: the actual Swift implementation of a new function
  ///
  ///  - Returns: a new function as ``EmacsValue`` that can be called via `funcall` or `apply`.
  ///
  ///  - Throws: ``EmacsError`` if something goes wrong on the Emacs side.
  ///
  /// See <doc:DefiningLispFunctions> for examples.
  @discardableResult
  public func defun<
    T1: EmacsConvertible,
    T2: EmacsConvertible,
    T3: EmacsConvertible,
    T4: EmacsConvertible
  >(
    _ name: String? = nil,
    with docstring: String = "",
    function: @escaping (T1, T2, T3, T4) throws -> Void
  ) throws -> EmacsValue {
    let wrapped = DefunImplementation(function)
    return try defun(named: name, with: docstring, function: wrapped)
  }
  /// Define a Lisp function with four parameters out of the given closure.
  ///
  ///  - Parameters:
  ///    - name: the name of a new function, can be `nil` for lambda functions
  ///    - with: the docstring for the new function
  ///    - function: the actual Swift implementation of a new function
  ///
  ///  - Returns: a new function as ``EmacsValue`` that can be called via `funcall` or `apply`.
  ///
  ///  - Throws: ``EmacsError`` if something goes wrong on the Emacs side.
  ///
  /// See <doc:DefiningLispFunctions> for examples.
  @discardableResult
  public func defun<
    T1: EmacsConvertible,
    T2: EmacsConvertible,
    T3: EmacsConvertible,
    T4: EmacsConvertible
  >(
    _ name: String? = nil,
    with docstring: String = "",
    function: @escaping (Environment, T1, T2, T3, T4) throws -> Void
  ) throws -> EmacsValue {
    let wrapped = DefunImplementation(function)
    return try defun(named: name, with: docstring, function: wrapped)
  }

  /// Define a Lisp function with five parameters out of the given closure.
  ///
  ///  - Parameters:
  ///    - name: the name of a new function, can be `nil` for lambda functions
  ///    - with: the docstring for the new function
  ///    - function: the actual Swift implementation of a new function
  ///
  ///  - Returns: a new function as ``EmacsValue`` that can be called via `funcall` or `apply`.
  ///
  ///  - Throws: ``EmacsError`` if something goes wrong on the Emacs side.
  ///
  /// See <doc:DefiningLispFunctions> for examples.
  @discardableResult
  public func defun<
    T1: EmacsConvertible,
    T2: EmacsConvertible,
    T3: EmacsConvertible,
    T4: EmacsConvertible,
    T5: EmacsConvertible,
    R: EmacsConvertible
  >(
    _ name: String? = nil,
    with docstring: String = "",
    function: @escaping (T1, T2, T3, T4, T5) throws -> R
  ) throws -> EmacsValue {
    let wrapped = DefunImplementation(function)
    return try defun(named: name, with: docstring, function: wrapped)
  }
  /// Define a Lisp function with five parameters out of the given closure.
  ///
  ///  - Parameters:
  ///    - name: the name of a new function, can be `nil` for lambda functions
  ///    - with: the docstring for the new function
  ///    - function: the actual Swift implementation of a new function
  ///
  ///  - Returns: a new function as ``EmacsValue`` that can be called via `funcall` or `apply`.
  ///
  ///  - Throws: ``EmacsError`` if something goes wrong on the Emacs side.
  ///
  /// See <doc:DefiningLispFunctions> for examples.
  @discardableResult
  public func defun<
    T1: EmacsConvertible,
    T2: EmacsConvertible,
    T3: EmacsConvertible,
    T4: EmacsConvertible,
    T5: EmacsConvertible,
    R: EmacsConvertible
  >(
    _ name: String? = nil,
    with docstring: String = "",
    function: @escaping (Environment, T1, T2, T3, T4, T5) throws -> R
  ) throws -> EmacsValue {
    let wrapped = DefunImplementation(function)
    return try defun(named: name, with: docstring, function: wrapped)
  }
  /// Define a Lisp function with five parameters out of the given closure.
  ///
  ///  - Parameters:
  ///    - name: the name of a new function, can be `nil` for lambda functions
  ///    - with: the docstring for the new function
  ///    - function: the actual Swift implementation of a new function
  ///
  ///  - Returns: a new function as ``EmacsValue`` that can be called via `funcall` or `apply`.
  ///
  ///  - Throws: ``EmacsError`` if something goes wrong on the Emacs side.
  ///
  /// See <doc:DefiningLispFunctions> for examples.
  @discardableResult
  public func defun<
    T1: EmacsConvertible,
    T2: EmacsConvertible,
    T3: EmacsConvertible,
    T4: EmacsConvertible,
    T5: EmacsConvertible
  >(
    _ name: String? = nil,
    with docstring: String = "",
    function: @escaping (T1, T2, T3, T4, T5) throws -> Void
  ) throws -> EmacsValue {
    let wrapped = DefunImplementation(function)
    return try defun(named: name, with: docstring, function: wrapped)
  }
  /// Define a Lisp function with five parameters out of the given closure.
  ///
  ///  - Parameters:
  ///    - name: the name of a new function, can be `nil` for lambda functions
  ///    - with: the docstring for the new function
  ///    - function: the actual Swift implementation of a new function
  ///
  ///  - Returns: a new function as ``EmacsValue`` that can be called via `funcall` or `apply`.
  ///
  ///  - Throws: ``EmacsError`` if something goes wrong on the Emacs side.
  ///
  /// See <doc:DefiningLispFunctions> for examples.
  @discardableResult
  public func defun<
    T1: EmacsConvertible,
    T2: EmacsConvertible,
    T3: EmacsConvertible,
    T4: EmacsConvertible,
    T5: EmacsConvertible
  >(
    _ name: String? = nil,
    with docstring: String = "",
    function: @escaping (Environment, T1, T2, T3, T4, T5) throws -> Void
  ) throws -> EmacsValue {
    let wrapped = DefunImplementation(function)
    return try defun(named: name, with: docstring, function: wrapped)
  }
  #endif
}
