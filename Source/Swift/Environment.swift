import EmacsModule

public final class Environment {
  internal let raw: UnsafeMutablePointer<emacs_env>
  internal lazy var swiftError: EmacsValue = {
    let symbol = try! intern("swift-error")
    let _ = try! funcall(
      "define-error", with: symbol,
      "Exception from a Swift module")
    return symbol
  }()

  public init(from: UnsafeMutablePointer<emacs_env>) {
    raw = from
  }

  public init(from: UnsafeMutablePointer<emacs_runtime>) {
    raw = from.pointee.get_environment(from)!
  }

  public func intern(_ name: String) throws -> EmacsValue {
    if !name.unicodeScalars.allSatisfy({ $0.isASCII }) {
      throw EmacsError.nonASCIISymbol(value: name)
    }
    return EmacsValue(from: raw.pointee.intern(raw, name))
  }
}
