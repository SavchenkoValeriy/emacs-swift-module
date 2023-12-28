//
// CallTests.swift
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
