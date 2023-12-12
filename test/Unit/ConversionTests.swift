import EmacsMock
@testable import EmacsSwiftModule
import XCTest

class ConversionTests: XCTestCase {
  func testIntConversion() throws {
    let mock = EnvironmentMock()
    let env = mock.environment
    let value = try 42.convert(within: env)

    XCTAssertEqual(try Int.convert(from: value, within: env), 42)
  }

  func testDoubleConversion() throws {
    let mock = EnvironmentMock()
    let env = mock.environment
    let value = try 36.6.convert(within: env)

    XCTAssertEqual(try Double.convert(from: value, within: env), 36.6)
  }

  func testBoolConversion() throws {
    let mock = EnvironmentMock()
    let env = mock.environment

    let falseValue = false.convert(within: env)
    XCTAssertFalse(try Bool.convert(from: falseValue, within: env))
    XCTAssert(try env.isNil(falseValue))

    let trueValue = true.convert(within: env)
    XCTAssert(try Bool.convert(from: trueValue, within: env))
    XCTAssert(try env.isNotNil(trueValue))

    let intValue = try 42.convert(within: env)
    XCTAssert(try Bool.convert(from: intValue, within: env))
    XCTAssert(try env.isNotNil(intValue))
  }

  func testStringConversion() throws {
    let mock = EnvironmentMock()
    let env = mock.environment
    let value = try "hello".convert(within: env)

    XCTAssertEqual(try String.convert(from: value, within: env), "hello")
  }

  func testUtf8StringConversion() throws {
    let mock = EnvironmentMock()
    let env = mock.environment
    let value = try "привет 🖖".convert(within: env)

    XCTAssertEqual(try String.convert(from: value, within: env), "привет 🖖")
  }

  func testStringLifetime() throws {
    let swiftString: String

    do {
      let mock = EnvironmentMock()
      let env = mock.environment
      let value = try "hello".convert(within: env)
      swiftString = try String.convert(from: value, within: env)
    }

    XCTAssertEqual(swiftString, "hello")
  }

  func testOptionalConversion() throws {
    let mock = EnvironmentMock()
    let env = mock.environment

    var optInt: Int? = nil
    let nilValue = try optInt.convert(within: env)
    XCTAssert(try env.isNil(nilValue))
    XCTAssertNil(try Int?.convert(from: nilValue, within: env))

    optInt = 42
    let value = try optInt.convert(within: env)
    XCTAssertEqual(try Int.convert(from: value, within: env), 42)
  }

  func testArrayConversion() throws {
    let mock = EnvironmentMock()
    let env = mock.environment

    let original = [1, 5, 10]
    let value = try original.convert(within: env)
    XCTAssertEqual(try [Int].convert(from: value, within: env), original)

    let empty = try [Double]().convert(within: env)
    XCTAssertEqual(try [Double].convert(from: empty, within: env), [])
  }

  func testOpaqueArrayConversion() throws {
    let mock = EnvironmentMock()
    let env = mock.environment

    let original = try [42.convert(within: env), true.convert(within: env), "hello".convert(within: env)]
    let value = try original.convert(within: env)

    let converted = try [EmacsValue].convert(from: value, within: env)

    XCTAssertEqual(converted.count, 3)
    XCTAssertEqual(try Int.convert(from: converted[0], within: env), 42)
    XCTAssert(try Bool.convert(from: converted[1], within: env))
    XCTAssertEqual(try String.convert(from: converted[2], within: env), "hello")
  }

  class A: OpaquelyEmacsConvertible {
    let x: Int

    init(_ param: Int) {
      x = param
    }
  }

  class B: OpaquelyEmacsConvertible {
    let y: Double

    init(_ param: Double) {
      y = param
    }
  }

  func testOpaquelyConvertible() throws {
    let mock = EnvironmentMock()
    let env = mock.environment

    let first = A(42)
    let second = A(10)
    let third = B(36.6)

    var value = try first.convert(within: env)
    XCTAssertEqual(try A.convert(from: value, within: env).x, first.x)

    value = try second.convert(within: env)
    XCTAssertEqual(try A.convert(from: value, within: env).x, second.x)

    value = try third.convert(within: env)
    XCTAssertEqual(try B.convert(from: value, within: env).y, third.y)
  }

  func testOpaquelyConvertibleSurviveInLisp() throws {
    let mock = EnvironmentMock()
    let env = mock.environment

    var value: EmacsValue
    do {
      let a = A(42)
      value = try a.convert(within: env)
      // a's retain count decreases here
    }

    XCTAssertEqual(try A.convert(from: value, within: env).x, 42)
  }

  func testOpaquelyConvertibleSurviveInSwift() throws {
    let a = A(42)
    let b: A

    var value: EmacsValue
    do {
      let mock = EnvironmentMock()
      let env = mock.environment
      value = try a.convert(within: env)
      b = try A.convert(from: value, within: env)
      // env and all its values are gone now
    }

    XCTAssertEqual(b.x, 42)
  }

  func testConversionFailure() throws {
    let mock = EnvironmentMock()
    let env = mock.environment

    let value = try 42.convert(within: env)
    XCTAssertThrowsError(try Double.convert(from: value, within: env))
    XCTAssertThrowsError(try String.convert(from: value, within: env))
    XCTAssertThrowsError(try A.convert(from: value, within: env))
  }
}
