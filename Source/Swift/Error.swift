//
// Error.swift
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

/// The main type representing Emacs errors.
///
/// Don't be shy throwing if something goes wrong, the inner machinery will catch it properly
/// and surface it to Emacs in the most appropriate way.
public enum EmacsError: Error {
  /// Emacs symbols are allowed to only have ASCII symbols, if we get something else this is the error.
  ///
  /// - Parameter value: the actual non-ASCII string causing the problem.
  case nonASCIISymbol(value: String)
  /// Custom error with a message.
  ///
  /// Perfect for situations when you want to show a message with your error, but don't want to bother
  /// with creating anything special for that.
  ///
  /// - Parameter message: a message to be shown with the error.
  case customError(message: String)
  /// Wrong type error.
  ///
  /// Probably the most useful error type for Swift since we require strong typing and it will be
  /// the most common reason we throw.
  ///
  /// - Parameters:
  ///   - expected: the name of the expected type.
  ///   - actual: the name of the actual type that we received instead.
  ///   - value: the Emacs value that caused all the trouble.
  case wrongType(expected: String, actual: String, value: EmacsValue)
  /// Generic signal error.
  ///
  /// In general, the majority of errors in Emacs Lisp are signals with a symbol and some data
  /// attached to it. And since we can't cover them all in this enum, this is a way to bundle them
  /// together.
  ///
  /// - Parameters:
  ///   - symbol: the symbol categorizing this signal.
  ///   - data: supplementary data.
  case signal(symbol: EmacsValue, data: EmacsValue)
  /// Emacs thrown exception.
  ///
  /// In addition to signals, Emacs provides less critical easier to catch concept of `throw`s.
  /// This error type represents exactly that.
  ///
  /// - Parameters:
  ///   - tag: the symbol categorizing this exception.
  ///   - value: supplementary value.
  case thrown(tag: EmacsValue, value: EmacsValue)
  /// Emacs user interruption (C-g).
  ///
  /// User can request execution interruption at any time, if you are trying to do something
  /// with environment after that, this exception will be thrown.
  ///
  /// It is recommended to stop any work as soon as possible upon receiving user interruptions.
  case interrupted
  /// Trying to use feature not available in the current version of Emacs.
  ///
  /// - Parameter what: description of the unsupported operation.
  case unsupported(what: String)
  /// Using ``Environment`` outside of its scope.
  ///
  /// See <doc:Lifetimes> for more details.
  case lifetimeViolation
  /// Using ``Environment`` in a different thread than issued it.
  ///
  /// See <doc:Lifetimes> for more details.
  case threadModelViolation
  /// If everything went to hell...
  case unknown
}

extension Environment {
  /// This is a single check point of all Emacs-side error-handling we do.
  ///
  /// It checks if Emacs has non-local error state and throws and exception if that's true.
  /// It simply returns the given value if Emacs is in no-error state.
  ///
  /// Since we are only interested in Emacs error states when we ask Emacs to execute something,
  /// it is natural to attach such checks to return values of Environment's inner calls.
  ///
  /// `check` clears the error state after the call, so it's absolutely to catch an exception and continue
  /// working with the environment like nothing happened.
  ///
  ///  - Parameter result: wrapped value that we are "checking" for errors.
  ///  - Returns: the checked value if we encountered no errors.
  ///  - Throws: an instance of `EmacsError` if Emacs was in error state.
  func check<T>(_ result: T) throws -> T {
    if interrupted() {
      throw EmacsError.interrupted
    }

    var symbolOrTag: emacs_value?
    var dataOrValue: emacs_value?

    switch raw.pointee.non_local_exit_get(raw, &symbolOrTag, &dataOrValue) {
    case emacs_funcall_exit_return:
      return result

    case emacs_funcall_exit_signal:
      raw.pointee.non_local_exit_clear(raw)
      throw EmacsError.signal(
        symbol: EmacsValue(from: symbolOrTag),
        data: EmacsValue(from: dataOrValue)
      )

    case emacs_funcall_exit_throw:
      raw.pointee.non_local_exit_clear(raw)
      throw EmacsError.thrown(
        tag: EmacsValue(from: symbolOrTag),
        value: EmacsValue(from: dataOrValue)
      )

    case let status:
      // Shouldn't get here, but just in case let's stop early.
      fatalError("Received unexpected exit status: \(status)")
    }
  }

  /// Return true if this environment is in Emacs error state.
  func inErrorState() -> Bool {
    raw.pointee.non_local_exit_check(raw) != emacs_funcall_exit_return
  }

  /// Signal a Swift error with the given message.
  func error(with message: String) {
    error(tag: swiftError, with: message)
  }

  /// Signal a custom error with the given arguments.
  ///
  /// It replicates Emacs Lisp `error` function.
  /// - Parameters:
  ///   - tag: the symbol categorizing this error, it should've been defined with `define-error`
  ///   Emacs Lisp function to be properly handled by Emacs.
  ///   - args: supplementary data for the error.
  func error(tag: EmacsValue, with args: EmacsConvertible...) {
    signal(tag, with: try! apply("list", with: args))
  }

  func signal(_ symbol: EmacsValue, with data: EmacsValue) {
    raw.pointee.non_local_exit_signal(raw, symbol.raw, data.raw)
  }

  func throwForTag(_ tag: EmacsValue, with value: EmacsValue) {
    raw.pointee.non_local_exit_throw(raw, tag.raw, value.raw)
  }

  /// Checks whether the user interrupted execution of the current function.
  ///
  /// It is recommended to stop work as soon as possible, and check this condition
  /// in long-running tasks.
  ///
  /// - Returns: `true` if the environment received interruption signal from the user.
  public func interrupted() -> Bool {
    if version == .Emacs25 {
      return false
    }
    return raw.pointee.should_quit(raw)
  }
}
