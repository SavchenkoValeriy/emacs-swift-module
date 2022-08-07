/// Emacs named symbol
public struct Symbol: EmacsConvertible {
  public let name: String

  public init(name: String) {
    self.name = name
  }

  public func convert(within env: Environment) throws -> EmacsValue {
    return try env.intern(name)
  }

  public static func convert(from value: EmacsValue, within env: Environment)
    throws -> Symbol
  {
    return Symbol(name: try env.funcall("symbol-name", with: value))
  }
}

/// Emacs cons cell
public struct ConsCell<CarType, CdrType>: EmacsConvertible
  where CarType: EmacsConvertible, CdrType: EmacsConvertible {
  public var car: CarType
  public var cdr: CdrType

  public init(car: CarType, cdr: CdrType) {
    self.car = car
    self.cdr = cdr
  }

  public func convert(within env: Environment) throws -> EmacsValue {
    try env.funcall("cons", with: car, cdr)
  }

  public static func convert(from: EmacsValue, within env: Environment) throws -> ConsCell {
    let car: CarType = try env.funcall("car", with: from)
    let cdr: CdrType = try env.funcall("cdr", with: from)
    return ConsCell(car: car, cdr: cdr)
  }
}
