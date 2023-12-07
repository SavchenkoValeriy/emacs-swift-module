//
// Channel+Hooks+Boilerplate.swift
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
extension Channel {
  /// Make a Swift callback out of an Emacs hook's name.
  ///
  /// This allows us to use Emacs hooks as callbacks in Swift APIs.
  /// Please, see <doc:AsyncCallbacks> for more details on that.
  ///
  /// - Parameter function: a name of a Lisp hook to turn into callback.
  /// - Returns: a callback that if called, will eventually run the hook.
  public func hook(_ hook: String)
    -> () -> Void
  {
    return { [self] in
      register {
        env in try env.funcall("run-hooks", with: Symbol(name: hook))
      }
    }
  }

  #if swift(>=5.9)
    /// Make a Swift callback out of an Emacs hook's name.
    ///
    /// This allows us to use Emacs hooks as callbacks in Swift APIs.
    /// Please, see <doc:AsyncCallbacks> for more details on that.
    ///
    /// - Parameter function: a name of a Lisp hook to turn into callback.
    /// - Returns: a callback that if called, will eventually run the hook.
    public func hook<each T: EmacsConvertible>(_ hook: String)
      -> (repeat each T) -> Void
    {
      return { [self] (arg: repeat each T) in
        register {
          env in
          try withTupleAsArray(repeat each arg) {
            argsAsArray in
            var args: [EmacsConvertible] = [Symbol(name: hook)]
            args.append(contentsOf: argsAsArray)
            try env.apply("run-hook-with-args", with: args)
          }
        }
      }
    }
  #else
    /// Make a Swift callback out of an Emacs hook's name.
    ///
    /// This allows us to use Emacs hooks as callbacks in Swift APIs.
    /// Please, see <doc:AsyncCallbacks> for more details on that.
    ///
    /// - Parameter function: a name of a Lisp hook to turn into callback.
    /// - Returns: a callback that if called, will eventually run the hook.
    public func hook<T: EmacsConvertible>(_ hook: String)
      -> (T) -> Void
    {
      return { [self] arg in
        register {
          env in
          try env.funcall("run-hook-with-args", with: Symbol(name: hook), arg)
        }
      }
    }
    /// Make a Swift callback out of an Emacs hook's name.
    ///
    /// This allows us to use Emacs hooks as callbacks in Swift APIs.
    /// Please, see <doc:AsyncCallbacks> for more details on that.
    ///
    /// - Parameter function: a name of a Lisp hook to turn into callback.
    /// - Returns: a callback that if called, will eventually run the hook.
    public func hook<T1: EmacsConvertible, T2: EmacsConvertible>(
      _ hook: String
    ) -> (T1, T2) -> Void {
      return { [self] (arg1, arg2) in
        register {
          env in
          try env.funcall(
            "run-hook-with-args", with: Symbol(name: hook), arg1, arg2)
        }
      }
    }
    /// Make a Swift callback out of an Emacs hook's name.
    ///
    /// This allows us to use Emacs hooks as callbacks in Swift APIs.
    /// Please, see <doc:AsyncCallbacks> for more details on that.
    ///
    /// - Parameter function: a name of a Lisp hook to turn into callback.
    /// - Returns: a callback that if called, will eventually run the hook.
    public func hook<
      T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible
    >(
      _ hook: String
    ) -> (T1, T2, T3) -> Void {
      return { [self] (arg1, arg2, arg3) in
        register {
          env in
          try env.funcall(
            "run-hook-with-args", with: Symbol(name: hook), arg1, arg2, arg3)
        }
      }
    }
    /// Make a Swift callback out of an Emacs hook's name.
    ///
    /// This allows us to use Emacs hooks as callbacks in Swift APIs.
    /// Please, see <doc:AsyncCallbacks> for more details on that.
    ///
    /// - Parameter function: a name of a Lisp hook to turn into callback.
    /// - Returns: a callback that if called, will eventually run the hook.
    public func hook<
      T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible,
      T4: EmacsConvertible
    >(
      _ hook: String
    ) -> (T1, T2, T3, T4) -> Void {
      return { [self] (arg1, arg2, arg3, arg4) in
        register {
          env in
          try env.funcall(
            "run-hook-with-args", with: Symbol(name: hook), arg1, arg2, arg3,
            arg4)
        }
      }
    }
    /// Make a Swift callback out of an Emacs hook's name.
    ///
    /// This allows us to use Emacs hooks as callbacks in Swift APIs.
    /// Please, see <doc:AsyncCallbacks> for more details on that.
    ///
    /// - Parameter function: a name of a Lisp hook to turn into callback.
    /// - Returns: a callback that if called, will eventually run the hook.
    public func hook<
      T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible,
      T4: EmacsConvertible, T5: EmacsConvertible
    >(
      _ hook: String
    ) -> (T1, T2, T3, T4, T5) -> Void {
      return { [self] (arg1, arg2, arg3, arg4, arg5) in
        register {
          env in
          try env.funcall(
            "run-hook-with-args", with: Symbol(name: hook), arg1, arg2, arg3,
            arg4, arg5)
        }
      }
    }
  #endif
}
