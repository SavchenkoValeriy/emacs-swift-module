import XCTest
@testable import EmacsSwiftModule
import EmacsMock

class ConversionTests: XCTestCase {
  func testIntConversion() throws {
    let mock = EnvironmentMock()
    let env = mock.environment;
    let value = try 42.convert(within: env)

    XCTAssertEqual(try Int.convert(from: value, within: env), 42);
  }

  func testStringConversion() throws {
    let mock = EnvironmentMock()
    let env = mock.environment;
    let value = try "hello".convert(within: env)

    XCTAssertEqual(try String.convert(from: value, within: env), "hello");
  }

  func testUtf8StringConversion() throws {
    let mock = EnvironmentMock()
    let env = mock.environment;
    let value = try "привет 🖖".convert(within: env)

    XCTAssertEqual(try String.convert(from: value, within: env), "привет 🖖");
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
