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

  func testFunctionWithEnv() throws {
    let mock = EnvironmentMock()
    let env = mock.environment

    try env.defun("fact") {
      (env: Environment, n: Int) throws in
      if n <= 1 {
        return 1
      }
      return try n * env.funcall("fact", with: n - 1)
    }

    XCTAssertEqual(try env.funcall("fact", with: 4) as Int, 24)
  }

  func testLambda() throws {
    let mock = EnvironmentMock()
    let env = mock.environment

    var called = false

    let trivial = try env.defun {
      called = true
    }

    try env.funcall(trivial)
    XCTAssert(called)
  }

  func testManyArgs() throws {
    #if swift(<5.9)
      throw XCTSkip("This test requires at least Swift 5.9")
    #else

      let mock = EnvironmentMock()
      let env = mock.environment

      try env.defun("many-args") {
        (
          a: Int,
          b: Int,
          c: Int,
          d: Int,
          e: Int,
          f: Int,
          g: Int,
          h: Int,
          i: Int,
          j: Int
        ) -> Int in
        a + b + c + d + e + f + g + h + i + j
      }

      let result: Int = try env.funcall("many-args", with: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
      XCTAssertEqual(result, 55)
    #endif
  }

  func testVoidReturnType() throws {
    let mock = EnvironmentMock()
    let env = mock.environment

    try env.defun("void") {}

    let value = try env.funcall("void")
    XCTAssert(try env.isNil(value))
  }

  func testSwiftException() throws {
    let mock = EnvironmentMock()
    let env = mock.environment

    struct MyError: Error {
      let message: String
    }

    try env.defun("throws") {
      throw MyError(message: "Runtime error")
    }

    XCTAssertThrowsError(try env.funcall("throws"))
  }
}
