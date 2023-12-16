//
// Lisp+Types.swift
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

/// Emacs named symbol
public struct Symbol: EmacsConvertible {
  public let name: String

  public init(name: String) {
    self.name = name
  }

  public func convert(within env: Environment) throws -> EmacsValue {
    try env.intern(name)
  }

  public static func convert(from value: EmacsValue, within env: Environment)
    throws -> Symbol {
    try Symbol(name: env.funcall("symbol-name", with: value))
  }
}

/// Emacs cons cell
public struct ConsCell<CarType, CdrType> {
  public var car: CarType
  public var cdr: CdrType

  public init(car: CarType, cdr: CdrType) {
    self.car = car
    self.cdr = cdr
  }
}

extension ConsCell: EmacsConvertible
  where CarType: EmacsConvertible, CdrType: EmacsConvertible {
  public func convert(within env: Environment) throws -> EmacsValue {
    try env.funcall("cons", with: car, cdr)
  }

  public static func convert(from: EmacsValue, within env: Environment) throws
    -> ConsCell {
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
  public mutating func next() -> Element? {
    guard case let .Cons(element, nested) = self else {
      return nil
    }
    self = nested
    return element
  }
}

/// Convenient conversions to and from arrays
public extension List {
  /// Construct List from Array.
  init(from array: [Element]) {
    var list: List = .Nil
    for element in array.reversed() {
      list = .Cons(head: element, tail: list)
    }
    self = list
  }

  /// Construct List from the given elements.
  init(_ elements: Element...) {
    self.init(from: elements)
  }

  /// Construct Array from List.
  func toArray() -> [Element] {
    map { $0 }
  }
}

extension List: EmacsConvertible where Element: EmacsConvertible {
  public func convert(within env: Environment) throws -> EmacsValue {
    try env.apply("list", with: toArray())
  }

  public static func convert(from: EmacsValue, within env: Environment) throws
    -> List<Element> {
    var array: [Element] = []
    var list = from
    // We could've constructed it recursively, but lists can get pretty long, so it's better
    // not to take any chancec with stack overflowing.
    while try env.isNotNil(list) {
      try array.append(env.funcall("car", with: list))
      list = try env.funcall("cdr", with: list)
    }
    return List(from: array)
  }
}
