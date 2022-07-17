import EmacsModule

public struct EmacsValue {
  internal let raw: emacs_value?
  internal init(from: emacs_value?) {
    raw = from
  }
}

public protocol EmacsConvertible {
  func convert(within env: Environment) throws -> EmacsValue
  static func convert(from: EmacsValue, within env: Environment) throws -> Self
}

extension EmacsValue: EmacsConvertible {
  public func convert(within env: Environment) -> EmacsValue {
    return self
  }

  public static func convert(from: EmacsValue, within env: Environment)
    -> EmacsValue
  {
    return from
  }
}

extension String: EmacsConvertible {
  public func convert(within env: Environment) throws -> EmacsValue {
    return try env.make(self)
  }

  public static func convert(from: EmacsValue, within env: Environment) throws
    -> Self
  {
    return try env.toString(from)
  }
}

extension Bool: EmacsConvertible {
  public func convert(within env: Environment) -> EmacsValue {
    return self ? env.t : env.Nil
  }

  public static func convert(from value: EmacsValue, within env: Environment)
    -> Bool
  {
    return env.isNotNil(value)
  }
}

extension Int: EmacsConvertible {
  public func convert(within env: Environment) throws -> EmacsValue {
    return try env.make(self)
  }

  public static func convert(from value: EmacsValue, within env: Environment)
    throws -> Int
  {
    return try env.toInt(value)
  }
}

extension Double: EmacsConvertible {
  public func convert(within env: Environment) throws -> EmacsValue {
    return try env.make(self)
  }

  public static func convert(from value: EmacsValue, within env: Environment)
    throws -> Double
  {
    return try env.toDouble(value)
  }
}

extension Array: EmacsConvertible where Element: EmacsConvertible {
  public func convert(within env: Environment) throws -> EmacsValue {
    return try env.make(self.map { try $0.convert(within: env) })
  }

  public static func convert(from value: EmacsValue, within env: Environment)
    throws -> [Element]
  {
    return try env.toArray(value).map {
      try Element.convert(from: $0, within: env)
    }
  }
}

extension Optional: EmacsConvertible where Wrapped: EmacsConvertible {
  public func convert(within env: Environment) throws -> EmacsValue {
    return try self?.convert(within: env) ?? env.Nil
  }

  public static func convert(from value: EmacsValue, within env: Environment)
    throws -> Self
  {
    return env.isNil(value)
      ? nil : try Wrapped.convert(from: value, within: env)
  }
}

public protocol OpaquelyEmacsConvertible: AnyObject, EmacsConvertible {}

extension OpaquelyEmacsConvertible {
  public func convert(within env: Environment) throws -> EmacsValue {
    try env.make(Unmanaged.passRetained(self).toOpaque()) { ptr in
      if let nonNullPtr = ptr {
        Unmanaged<AnyObject>.fromOpaque(nonNullPtr).release()
      }
    }
  }

  public static func convert(from value: EmacsValue, within env: Environment)
    throws -> Self
  {
    let candidate = Unmanaged<AnyObject>.fromOpaque(try env.toOpaque(value))
      .takeUnretainedValue()
    guard let result = candidate as? Self else {
      throw EmacsError.wrongType(
        expected: "\(Self.self)", actual: "\(type(of: candidate))", value: value
      )
    }
    return result
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
  func make(_ from: String) throws -> EmacsValue {
    return EmacsValue(
      from: try check(raw.pointee.make_string(raw, from, from.count)))
  }
  func make(_ from: Int) throws -> EmacsValue {
    return EmacsValue(from: try check(raw.pointee.make_integer(raw, from)))
  }
  func make(_ from: Double) throws -> EmacsValue {
    return EmacsValue(from: try check(raw.pointee.make_float(raw, from)))
  }
  func make(_ from: [EmacsValue]) throws -> EmacsValue {
    return try apply("vector", with: from)
  }
  func make(
    _ value: RawOpaquePointer,
    with finalizer: @escaping RawFinalizer = { _ in () }
  ) throws -> EmacsValue {
    return EmacsValue(
      from: try check(raw.pointee.make_user_ptr(raw, finalizer, value)))
  }

  //
  // Converter functions
  //
  func toString(_ value: EmacsValue) throws -> String {
    var len = 0
    let _ = try check(
      raw.pointee.copy_string_contents(raw, value.raw, nil, &len))
    var buf = [CChar](repeating: 0, count: len)
    let _ = raw.pointee.copy_string_contents(raw, value.raw, &buf, &len)
    return String(cString: buf)
  }
  func toInt(_ value: EmacsValue) throws -> Int {
    return try Int(check(raw.pointee.extract_integer(raw, value.raw)))
  }
  func toDouble(_ value: EmacsValue) throws -> Double {
    return try Double(check(raw.pointee.extract_float(raw, value.raw)))
  }
  func toArray(_ value: EmacsValue) throws -> [EmacsValue] {
    let size = try check(raw.pointee.vec_size(raw, value.raw))
    var result = [EmacsValue](repeating: value, count: size)

    for i in 0..<size {
      result[i] = EmacsValue(
        from: try check(raw.pointee.vec_get(raw, value.raw, i)))
    }

    return result
  }
  func toOpaque(_ value: EmacsValue) throws -> RawOpaquePointer {
    return try check(raw.pointee.get_user_ptr(raw, value.raw))!
  }
  public func isNil(_ value: EmacsValue) -> Bool {
    return !isNotNil(value)
  }
  public func isNotNil(_ value: EmacsValue) -> Bool {
    return raw.pointee.is_not_nil(raw, value.raw)
  }
}
