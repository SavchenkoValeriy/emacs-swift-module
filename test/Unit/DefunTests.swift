import EmacsMock
@testable import EmacsSwiftModule
import XCTest

class DefunTests: XCTestCase {
  func testTrivial() throws {
    let mock = EnvironmentMock()
    let env = mock.environment

    var called = false

    try env.defun("trivial") {
      called = true
    }

    try env.funcall("trivial")
    XCTAssert(called)
  }

  func testFunctionFinalizer() throws {
    let mock = EnvironmentMock()
    let env = mock.environment

    var accumulator = ""

    // We need this closure capture and keep some piece
    // of data alive, so that if we don't clean it up, it
    // would end up in a leak.
    try env.defun("add") {
      (str: String) in accumulator += str
    }

    try env.funcall("add", with: "Hello")
    XCTAssertEqual(accumulator, "Hello")

    try env.funcall("add", with: ", ")
    XCTAssertEqual(accumulator, "Hello, ")

    try env.funcall("add", with: "World")
    XCTAssertEqual(accumulator, "Hello, World")

    try env.funcall("add", with: "!")
    XCTAssertEqual(accumulator, "Hello, World!")
  }
}
