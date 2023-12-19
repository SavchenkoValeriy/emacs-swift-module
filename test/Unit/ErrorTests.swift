import EmacsMock
@testable import EmacsSwiftModule
import XCTest

class ErrorTests: XCTestCase {
  func testWrongTypeError() throws {
    let mock = EnvironmentMock()
    let env = mock.environment

    XCTAssertThrowsError(try Int.convert(from: env.intern("nil"), within: env))
  }

  func testNumberOfArgsError() throws {
    let mock = EnvironmentMock()
    let env = mock.environment

    XCTAssertThrowsError(try env.funcall("car"))

    let lambda = try env.defun {
      (x: Int, y: Int) in x + y
    }

    XCTAssertThrowsError(try env.funcall(lambda, with: 1, 2, 3))
  }

  func testInterrupted() throws {
    let mock = EnvironmentMock()
    let env = mock.environment

    var called = false

    try env.defun("my-car") {
      (cons: ConsCell<Int, Int>) in
      called = true
      return cons.car
    }

    try env.funcall("my-car", with: ConsCell(car: 0, cdr: 1))
    XCTAssert(called)

    called = false
    mock.interrupt()

    // Fails during argument conversion because environment is interrupted
    XCTAssertThrowsError(try env.funcall("my-car", with: ConsCell(car: 0, cdr: 1)))
    XCTAssertFalse(called)
  }

  func testInterruptedPredicate() throws {
    let mock = EnvironmentMock()
    let env = mock.environment

    XCTAssertFalse(env.interrupted())
    XCTAssertFalse(env.inErrorState())

    mock.interrupt()

    XCTAssert(env.interrupted())
    XCTAssertFalse(env.inErrorState())
  }

  func testSignal() throws {
    let mock = EnvironmentMock()
    let env = mock.environment

    var called = false

    try env.defun("my-car") {
      (cons: ConsCell<Int, Int>) in
      called = true
      return cons.car
    }

    try env.funcall("my-car", with: ConsCell(car: 0, cdr: 1))
    XCTAssert(called)

    called = false
    mock.signal()

    // Fails during argument conversion because environment is in error state
    XCTAssertThrowsError(try env.funcall("my-car", with: ConsCell(car: 0, cdr: 1)))
    XCTAssertFalse(called)
  }

  func testThrownEmacsException() throws {
    let mock = EnvironmentMock()
    let env = mock.environment

    var called = false

    try env.defun("my-car") {
      (cons: ConsCell<Int, Int>) in
      called = true
      return cons.car
    }

    try env.funcall("my-car", with: ConsCell(car: 0, cdr: 1))
    XCTAssert(called)

    called = false
    mock.throwException()

    // Fails during argument conversion because environment is in error state
    XCTAssertThrowsError(try env.funcall("my-car", with: ConsCell(car: 0, cdr: 1)))
    XCTAssertFalse(called)
  }

  func testSignalInErrorState() throws {
    let mock = EnvironmentMock()
    let env = mock.environment

    XCTAssertFalse(env.interrupted())
    XCTAssertFalse(env.inErrorState())

    mock.signal()

    XCTAssertFalse(env.interrupted())
    XCTAssert(env.inErrorState())
  }

  func testEmacsExceptionInErrorState() throws {
    let mock = EnvironmentMock()
    let env = mock.environment

    XCTAssertFalse(env.interrupted())
    XCTAssertFalse(env.inErrorState())

    mock.throwException()

    XCTAssertFalse(env.interrupted())
    XCTAssert(env.inErrorState())
  }
}
