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

  public static func convert(from: EmacsValue, within env: Environment) throws
    -> ConsCell
  {
    let car: CarType = try env.funcall("car", with: from)
    let cdr: CdrType = try env.funcall("cdr", with: from)
    return ConsCell(car: car, cdr: cdr)
  }
}

/// A simple list implementation that allows the most transparent conversion between two worlds.
public enum List<Element> {
  /// Non-empty list having `head` as its element, and a tail list.
  indirect case Cons(head: Element, tail: List<Element>)
  /// Empty list
  case Nil
}

/// Allowing convenient iteration over the list
extension List: Sequence, IteratorProtocol {
  mutating public func next() -> Element? {
    guard case .Cons(let element, let nested) = self else {
      return nil
    }
    self = nested
    return element
  }
}

/// Convenienct conversions to and from arrays
extension List {
  /// Construct List from Array.
  public init(from array: [Element]) {
    var list: List = .Nil
    for element in array.reversed() {
      list = .Cons(head: element, tail: list)
    }
    self = list
  }

  /// Construct Array from List.
  public func toArray() -> [Element] {
    map { $0 }
  }
}

extension List: EmacsConvertible where Element: EmacsConvertible {
  public func convert(within env: Environment) throws -> EmacsValue {
    try env.apply("list", with: toArray())
  }

  public static func convert(from: EmacsValue, within env: Environment) throws
    -> List<Element>
  {
    var array: [Element] = []
    var list = from
    // We could've constructed it recursively, but lists can get pretty long, so it's better
    // not to take any chancec with stack overflowing.
    while env.isNotNil(list) {
      array.append(try env.funcall("car", with: list))
      list = try env.funcall("cdr", with: list)
    }
    return List(from: array)
  }
}
