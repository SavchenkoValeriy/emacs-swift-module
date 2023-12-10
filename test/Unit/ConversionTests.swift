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
}
