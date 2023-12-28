//
// ErrorTests.swift
// Copyright (C) 2022-2023 Valeriy Savchenko
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

  func testInvalidEnvironment() throws {
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
    env.invalidate()

    // Fails during argument conversion because environment is in error state
    XCTAssertThrowsError(try env.funcall("my-car", with: ConsCell(car: 0, cdr: 1)))
    XCTAssertFalse(called)
  }

  func testThreadModelViolation() throws {
    let mock = EnvironmentMock()
    let env = mock.environment

    try env.defun("void") {}

    XCTAssertNoThrow(try env.funcall("void"))

    let expectation = expectation(description: "'funcall' in another thread")

    DispatchQueue.global(qos: .background).async {
      if (try? env.funcall("void")) != nil {
        XCTFail("Managed to 'funcall' on another thread")
      }
      expectation.fulfill()
    }

    // Wait for the expectation
    waitForExpectations(timeout: 10) { error in
      if let error {
        XCTFail("Timeout with error: \(error.localizedDescription)")
      }
    }
  }

  func testLifetimeModelViolation() throws {
    let mock = EnvironmentMock()
    let env = mock.environment

    var storedEnvironment = env

    try env.defun("capture") {
      captured in storedEnvironment = captured
    }

    try env.defun("use") {
      try storedEnvironment.intern("variable")
    }

    // Right now storedEnvironment is valid
    XCTAssertNoThrow(try env.funcall("use"))

    try env.funcall("capture")
    // Now storedEnvironment is invalid since it's from the "capture" scope.
    XCTAssertThrowsError(try env.funcall("use"))
  }
}
