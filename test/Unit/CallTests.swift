import EmacsMock
@testable import EmacsSwiftModule
import XCTest

class CallTests: XCTestCase {
  func testSimpleCall() throws {
    let mock = EnvironmentMock()
    let env = mock.environment

    try env.defun("add") {
      (lhs: Int, rhs: Int) in
      lhs + rhs
    }

    let value = try env.funcall("add", with: 2, 3)
    XCTAssertEqual(try Int.convert(from: value, within: env), 5)
  }

  func testReturnTypeFromDecl() throws {
    let mock = EnvironmentMock()
    let env = mock.environment

    try env.defun("add") {
      (lhs: Int, rhs: Int) in
      lhs + rhs
    }

    let value: Int = try env.funcall("add", with: 2, 3)
    XCTAssertEqual(value, 5)
  }

  func testReturnTypeFromAs() throws {
    let mock = EnvironmentMock()
    let env = mock.environment

    try env.defun("add") {
      (lhs: Int, rhs: Int) in
      lhs + rhs
    }

    let value = try env.funcall("add", with: 2, 3) as Int
    XCTAssertEqual(value, 5)
  }

  func testReturnTypeFromArg() throws {
    let mock = EnvironmentMock()
    let env = mock.environment

    try env.defun("add") {
      (lhs: Int, rhs: Int) in
      lhs + rhs
    }

    func double(_ x: Int) -> Int {
      x * 2
    }

    XCTAssertEqual(try double(env.funcall("add", with: 2, 3)), 10)
  }

  func testApply() throws {
    let mock = EnvironmentMock()
    let env = mock.environment

    try env.defun("add") {
      (a: Int, b: Int, c: Int, d: Int) in
      a + b + c + d
    }

    let value = try env.apply("add", with: [2, 3, 4, 5])
    XCTAssertEqual(try Int.convert(from: value, within: env), 14)
  }

  func testApplyReturnType() throws {
    let mock = EnvironmentMock()
    let env = mock.environment

    try env.defun("add") {
      (a: Int, b: Int, c: Int, d: Int) in
      a + b + c + d
    }

    let value: Int = try env.apply("add", with: [2, 3, 4, 5])
    XCTAssertEqual(value, 14)
  }
}
