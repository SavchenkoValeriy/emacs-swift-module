//
// Channel+LispCallback+Boilerplate.swift
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
  /// Make a Swift callback out of an Emacs function.
  ///
  /// This allows us to use Emacs functions as callbacks in Swift APIs.
  /// Please, see <doc:AsyncCallbacks> for more details on that.
  ///
  /// - Parameter function: a Lisp function to turn into a callback.
  /// - Returns: a callback that if called, will eventually call the given function.
  public func callback(_ function: EmacsValue)
    -> () -> Void
  {
    return { [self] in
      register {
        env in try env.funcall(function)
      }
    }
  }

  #if swift(>=5.9)

    /// Make a Swift callback out of an Emacs function.
    ///
    /// This allows us to use Emacs functions as callbacks in Swift APIs.
    /// Please, see <doc:AsyncCallbacks> for more details on that.
    ///
    /// - Parameter function: a Lisp function to turn into a callback.
    /// - Returns: a callback that if called, will eventually call the given function.
    public func callback<each T: EmacsConvertible>(
      _ function: EmacsValue
    ) -> (repeat each T) -> Void {
      return { [self] (args: repeat each T) in
        register {
          env in
          try withTupleAsArray(repeat each args) {
            argsAsArray in
            try env.apply(function, with: argsAsArray)
          }
        }
      }
    }
  #else
    /// Make a Swift callback out of an Emacs function.
    ///
    /// This allows us to use Emacs functions as callbacks in Swift APIs.
    /// Please, see <doc:AsyncCallbacks> for more details on that.
    ///
    /// - Parameter function: a Lisp function to turn into a callback.
    /// - Returns: a callback that if called, will eventually call the given function.
    public func callback<T: EmacsConvertible>(_ function: EmacsValue)
      -> (T) -> Void
    {
      return { [self] arg in
        register {
          env in try env.funcall(function, with: arg)
        }
      }
    }

    /// Make a Swift callback out of an Emacs function.
    ///
    /// This allows us to use Emacs functions as callbacks in Swift APIs.
    /// Please, see <doc:AsyncCallbacks> for more details on that.
    ///
    /// - Parameter function: a Lisp function to turn into a callback.
    /// - Returns: a callback that if called, will eventually call the given function.
    public func callback<T1: EmacsConvertible, T2: EmacsConvertible>(
      _ function: EmacsValue
    ) -> (T1, T2) -> Void {
      return { [self] (arg1, arg2) in
        register {
          env in try env.funcall(function, with: arg1, arg2)
        }
      }
    }
    /// Make a Swift callback out of an Emacs function.
    ///
    /// This allows us to use Emacs functions as callbacks in Swift APIs.
    /// Please, see <doc:AsyncCallbacks> for more details on that.
    ///
    /// - Parameter function: a Lisp function to turn into a callback.
    /// - Returns: a callback that if called, will eventually call the given function.
    public func callback<
      T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible
    >(
      _ function: EmacsValue
    ) -> (T1, T2, T3) -> Void {
      return { [self] (arg1, arg2, arg3) in
        register {
          env in try env.funcall(function, with: arg1, arg2, arg3)
        }
      }
    }
    /// Make a Swift callback out of an Emacs function.
    ///
    /// This allows us to use Emacs functions as callbacks in Swift APIs.
    /// Please, see <doc:AsyncCallbacks> for more details on that.
    ///
    /// - Parameter function: a Lisp function to turn into a callback.
    /// - Returns: a callback that if called, will eventually call the given function.
    public func callback<
      T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible,
      T4: EmacsConvertible
    >(
      _ function: EmacsValue
    ) -> (T1, T2, T3, T4) -> Void {
      return { [self] (arg1, arg2, arg3, arg4) in
        register {
          env in try env.funcall(function, with: arg1, arg2, arg3, arg4)
        }
      }
    }
    /// Make a Swift callback out of an Emacs function.
    ///
    /// This allows us to use Emacs functions as callbacks in Swift APIs.
    /// Please, see <doc:AsyncCallbacks> for more details on that.
    ///
    /// - Parameter function: a Lisp function to turn into a callback.
    /// - Returns: a callback that if called, will eventually call the given function.
    public func callback<
      T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible,
      T4: EmacsConvertible, T5: EmacsConvertible
    >(
      _ function: EmacsValue
    ) -> (T1, T2, T3, T4, T5) -> Void {
      return { [self] (arg1, arg2, arg3, arg4, arg5) in
        register {
          env in try env.funcall(function, with: arg1, arg2, arg3, arg4, arg5)
        }
      }
    }
  #endif
}
