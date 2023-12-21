@testable import EmacsSwiftModule
import XCTest

class LispTypesTests: XCTestCase {
  func testSymbol() throws {
    let mock = EnvironmentMock()
    let env = mock.environment

    let value = try env.intern("a")

    let symbol = try Symbol.convert(from: value, within: env)

    XCTAssertEqual(symbol.name, "a")
    XCTAssertEqual(try Symbol.convert(from: symbol.convert(within: env), within: env).name, "a")
  }

  func testConsCell() throws {
    let mock = EnvironmentMock()
    let env = mock.environment

    let value = try env.funcall("cons", with: 10, "hello")
    let cons = try ConsCell<Int, String>.convert(from: value, within: env)
    XCTAssertEqual(cons.car, 10)
    XCTAssertEqual(cons.cdr, "hello")

    let converted = try cons.convert(within: env)
    let car: Int = try env.funcall("car", with: converted)
    let cdr: String = try env.funcall("cdr", with: converted)
    XCTAssertEqual(car, 10)
    XCTAssertEqual(cdr, "hello")
  }

  func testConsCellConversionFailure() throws {
    let mock = EnvironmentMock()
    let env = mock.environment

    let value = try 42.convert(within: env)
    XCTAssertThrowsError(try ConsCell<Int, String>.convert(from: value, within: env))
  }

  func testList() throws {
    let mock = EnvironmentMock()
    let env = mock.environment

    let list = List<Int>(2, 3, 10, 42)
    let value = try list.convert(within: env)

    let head: Int = try env.funcall("car", with: value)
    XCTAssertEqual(head, 2)
    let tail: List<Int> = try env.funcall("cdr", with: value)
    XCTAssertEqual(tail.toArray(), [3, 10, 42])

    let asCons = try ConsCell<Int, ConsCell<Int, List<Int>>>.convert(from: value, within: env)
    XCTAssertEqual(asCons.cdr.cdr.toArray(), [10, 42])

    let empty = try List<String>.convert(from: env.Nil, within: env)
    XCTAssert(empty.toArray().isEmpty)
  }

  func testListConversionFailure() throws {
    let mock = EnvironmentMock()
    let env = mock.environment

    let value = try 42.convert(within: env)
    XCTAssertThrowsError(try List<Int>.convert(from: value, within: env))
  }
}
