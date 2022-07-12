import EmacsModule

struct EmacsValue {
  let raw: emacs_value?
  public init(from: emacs_value?) {
    raw = from
  }
}

protocol EmacsConvertible {
  func convert(within env: Environment) throws -> EmacsValue
  static func convert(from: EmacsValue, within env: Environment) -> Self
}

extension EmacsValue: EmacsConvertible {
  func convert(within env: Environment) throws -> EmacsValue {
    return self
  }

  static func convert(from: EmacsValue, within env: Environment) -> EmacsValue {
    return from
  }
}

extension String: EmacsConvertible {
  func convert(within env: Environment) throws -> EmacsValue {
    return try env.make(self)
  }

  static func convert(from: EmacsValue, within env: Environment) -> Self {
    return env.toString(from)
  }
}

extension Bool: EmacsConvertible {
  func convert(within env: Environment) throws -> EmacsValue {
    return self ? env.t : env.Nil
  }

  static func convert(from value: EmacsValue, within env: Environment) -> Bool {
    return env.isNotNil(value)
  }
}

extension Int: EmacsConvertible {
  func convert(within env: Environment) throws -> EmacsValue {
    return try env.make(self)
  }

  static func convert(from value: EmacsValue, within env: Environment) -> Int {
    return env.toInt(value)
  }
}

extension Double: EmacsConvertible {
  func convert(within env: Environment) throws -> EmacsValue {
    return try env.make(self)
  }

  static func convert(from value: EmacsValue, within env: Environment) -> Double
  {
    return env.toDouble(value)
  }
}

protocol OpaquelyEmacsConvertible: AnyObject, EmacsConvertible {}

extension OpaquelyEmacsConvertible {
  func convert(within env: Environment) throws -> EmacsValue {
    try env.make(Unmanaged.passRetained(self).toOpaque()) { ptr in
      if let nonNullPtr = ptr {
        Unmanaged<AnyObject>.fromOpaque(nonNullPtr).release()
      }
    }
  }

  static func convert(from value: EmacsValue, within env: Environment) -> Self {
    return Unmanaged<Self>.fromOpaque(env.toOpaque(value))
      .takeUnretainedValue()
  }
}

extension Environment {
  public var Nil: EmacsValue {
    return try! intern("nil")
  }
  public var t: EmacsValue {
    return try! intern("t")
  }
  //
  // Value factories
  //
  public func make(_ from: String) throws -> EmacsValue {
    return EmacsValue(
      from: try check(raw.pointee.make_string(raw, from, from.count)))
  }
  public func make(_ from: Int) throws -> EmacsValue {
    return EmacsValue(from: try check(raw.pointee.make_integer(raw, from)))
  }
  public func make(_ from: Double) throws -> EmacsValue {
    return EmacsValue(from: try check(raw.pointee.make_float(raw, from)))
  }
  public func make(
    _ value: RawOpaquePointer,
    with finalizer: @escaping RawFinalizer = { _ in () }
  ) throws -> EmacsValue {
    return EmacsValue(
      from: try check(raw.pointee.make_user_ptr(raw, finalizer, value)))
  }

  //
  // Converter functions
  //
  public func toString(_ value: EmacsValue) -> String {
    var len = 0
    let _ = raw.pointee.copy_string_contents(raw, value.raw, nil, &len)
    var buf = [CChar](repeating: 0, count: len)
    let _ = raw.pointee.copy_string_contents(raw, value.raw, &buf, &len)
    return String(cString: buf)
  }
  public func toInt(_ value: EmacsValue) -> Int {
    return Int(raw.pointee.extract_integer(raw, value.raw))
  }
  public func toDouble(_ value: EmacsValue) -> Double {
    return Double(raw.pointee.extract_float(raw, value.raw))
  }
  public func toOpaque(_ value: EmacsValue) -> RawOpaquePointer {
    return raw.pointee.get_user_ptr(raw, value.raw)!
  }
  public func isNil(_ value: EmacsValue) -> Bool {
    return !isNotNil(value)
  }
  public func isNotNil(_ value: EmacsValue) -> Bool {
    return raw.pointee.is_not_nil(raw, value.raw)
  }
}
