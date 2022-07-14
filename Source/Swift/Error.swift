import EmacsModule

public enum EmacsError: Error {
  case nonASCIISymbol(value: String)
  case customError(message: String)
  case signal(symbol: EmacsValue, data: EmacsValue)
  case thrown(tag: EmacsValue, value: EmacsValue)
  case unknown
}

extension Environment {
  func check(_ rawValue: emacs_value?) throws -> emacs_value? {
    var symbolOrTag: emacs_value?
    var dataOrValue: emacs_value?
    switch raw.pointee.non_local_exit_get(raw, &symbolOrTag, &dataOrValue) {
    case emacs_funcall_exit_return:
      return rawValue
    case emacs_funcall_exit_signal:
      raw.pointee.non_local_exit_clear(raw)
      throw EmacsError.signal(
        symbol: EmacsValue(from: symbolOrTag),
        data: EmacsValue(from: dataOrValue))
    case emacs_funcall_exit_throw:
      raw.pointee.non_local_exit_clear(raw)
      throw EmacsError.thrown(
        tag: EmacsValue(from: symbolOrTag),
        value: EmacsValue(from: dataOrValue))
    case let status:
      fatalError("Received unexpected exit status: \(status)")
    }
  }
  public func error(with message: String) {
    signal(swiftError, with: try! funcall("list", with: message))
  }

  public func signal(_ symbol: EmacsValue, with data: EmacsValue) {
    raw.pointee.non_local_exit_signal(raw, symbol.raw, data.raw)
  }

  public func throwForTag(_ tag: EmacsValue, with value: EmacsValue) {
    raw.pointee.non_local_exit_throw(raw, tag.raw, value.raw)
  }
}
