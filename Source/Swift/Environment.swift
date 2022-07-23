import EmacsModule

/// Environment is **the** interaction point with Emacs. If you want to do anything on the Emacs side, you need to have an Environment.
///
/// Environment acts as a mediator for:
///  - calling Emacs Lisp functions
///  - checking Emacs values and their content
///  - exposing Swift functions to Emacs
///  - handling Emacs errors on the Swift side
///  - handling Swift errors on the Emacs side
public final class Environment {
  internal let raw: UnsafeMutablePointer<emacs_env>
  /// This is a symbol we use for surfacing Swift exceptions to Emacs Lisp.
  internal lazy var swiftError: EmacsValue = {
    let symbol = try! intern("swift-error")
    let _ = try! funcall(
      "define-error", with: symbol,
      "Exception from a Swift module")
    return symbol
  }()

  /// Construct the environment from raw C pointer.
  public init(from: UnsafeMutablePointer<emacs_env>) {
    raw = from
  }

  /// Construct the environment from the raw runtime C pointer.
  public init(from: UnsafeMutablePointer<emacs_runtime>) {
    raw = from.pointee.get_environment(from)!
  }

  /// Return the canonical Emacs symbol with the given name.
  ///
  /// It is equivalent to calling `intern` Emacs Lisp function and is required to communicate
  /// with Emacs symbols from Swift. Calling any Emacs Lisp function does involve interning
  /// its name first.
  ///  - Parameter name: the name of the symbol to get or create.
  ///  - Returns: the opaque Emacs value representing a Lisp symbol for the given name.
  ///  - Throws: `EmacsError.nonASCIISymbol` if the name has non-ASCII symbols (not allowed by Lisp).
  public func intern(_ name: String) throws -> EmacsValue {
    if !name.unicodeScalars.allSatisfy({ $0.isASCII }) {
      throw EmacsError.nonASCIISymbol(value: name)
    }
    return EmacsValue(from: raw.pointee.intern(raw, name))
  }
}
