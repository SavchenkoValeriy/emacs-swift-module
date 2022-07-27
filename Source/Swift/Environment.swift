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
  required init(from: UnsafeMutablePointer<emacs_env>) {
    raw = from
    // While we didn't have any environments live, we could've accumulated
    // a few things to clean, let's do it!
    cleanup()
  }

  /// Construct the environment from the raw runtime C pointer.
  public convenience init(from: UnsafeMutablePointer<emacs_runtime>) {
    self.init(from: from.pointee.get_environment(from)!)
  }

  deinit {
    // When we destroy the environment, we need to check if there is
    // anything we can cleanup in our memory.
    cleanup()
  }

  /// Return the canonical Emacs symbol with the given name.
  ///
  /// It is equivalent to calling `intern` Emacs Lisp function and is required to communicate
  /// with Emacs symbols from Swift. Calling any Emacs Lisp function does involve interning
  /// its name first.
  ///  - Parameter name: the name of the symbol to get or create.
  ///  - Returns: the opaque Emacs value representing a Lisp symbol for the given name.
  ///  - Throws: ``EmacsError.nonASCIISymbol`` if the name has non-ASCII symbols (not allowed by Lisp).
  public func intern(_ name: String) throws -> EmacsValue {
    if !name.unicodeScalars.allSatisfy({ $0.isASCII }) {
      throw EmacsError.nonASCIISymbol(value: name)
    }
    return EmacsValue(from: raw.pointee.intern(raw, name))
  }

  /// Return a persistent version of the given value.
  ///
  /// Call this method if you want to prolong the lifetime of the value
  /// and store it for some time after this environment is gone.
  ///  - Parameter value: the value to preserve.
  ///  - Returns: the same value, but with prolongued lifetime.
  ///  - Throws: ``EmacsError`` if something on the Emacs side goes wrong.
  public func preserve(_ value: EmacsValue) throws -> PersistentEmacsValue {
    return try PersistentEmacsValue(from: value, within: self)
  }

  /// Retain the given value.
  ///
  /// The semantics of this function are similar to Obj-C's own `retain`.
  /// Multiple `retain` calls will require as many `release` calls to follow
  /// in order to free the object.
  ///
  /// (See ``release(_:)``)
  ///
  /// > Warning: Please, try not to use this directly. Use ``PersistentEmacsValue`` or ``preserve(_:)`` instead.
  ///
  ///  - Parameter value: the value to be retained.
  ///  - Returns: retained copy of the value.
  ///  - Throws: ``EmacsError`` if something on the Emacs side goes wrong.
  public func retain(_ value: EmacsValue) throws -> EmacsValue {
    return EmacsValue(
      from: try check(raw.pointee.make_global_ref(raw, value.raw)))
  }

  /// Release the given value.
  ///
  /// The semantics of this function are similar to Obj-C's own `release`.
  /// Multiple `retain` calls will require as many `release` calls to follow
  /// in order to free the object.
  ///
  /// (See ``retain(_:)``)
  ///
  /// > Warning: Please, try not to use this directly. Use ``PersistentEmacsValue`` or ``preserve(_:)`` instead.
  ///
  ///  - Parameter value: the value to be released.
  ///  - Throws: ``EmacsError`` if something on the Emacs side goes wrong.
  public func release(_ value: EmacsValue) throws {
    let _ = try check(raw.pointee.free_global_ref(raw, value.raw))
  }
}
