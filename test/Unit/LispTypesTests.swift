import EmacsMock
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
}
