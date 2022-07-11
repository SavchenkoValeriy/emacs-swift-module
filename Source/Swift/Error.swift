import EmacsModule

enum EmacsError: Error {
  case nonASCIISymbol(value: String)
  case wrongTypeException(message: String)
  case unknown
}

extension Environment {
  internal func check(_ rawValue: emacs_value?) throws -> emacs_value? {
    var symbolOrTag: emacs_value?
    var dataOrValue: emacs_value?
    switch raw.pointee.non_local_exit_get(raw, &symbolOrTag, &dataOrValue) {
    case emacs_funcall_exit_return:
      return rawValue
    case emacs_funcall_exit_signal:
      throw EmacsError.unknown
    case emacs_funcall_exit_throw:
      throw EmacsError.unknown
    default:
      throw EmacsError.unknown
    }
  }
}
