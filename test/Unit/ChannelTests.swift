//
// ChannelTests.swift
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

class ChannelTests: XCTestCase {
  var mock: EnvironmentMock!
  var env: Environment { mock.environment }

  override func setUp() {
    mock = EnvironmentMock()
  }

  override func tearDown() {
    mock = nil
  }

  func testBufferOps() throws {
    let bufferName = try env.funcall("generate-new-buffer", with: "test")
    try env.funcall("set-buffer", with: bufferName)
    try env.funcall("insert", with: "Hllo, World")
    XCTAssertEqual(mock.currentBuffer.contents, "Hllo, World")

    try env.funcall("goto-char", with: 2)
    try env.funcall("insert", with: "e")
    XCTAssertEqual(mock.currentBuffer.contents, "Hello, World")

    try env.funcall("goto-char", with: env.funcall("point-max"))
    try env.funcall("insert", with: "!")
    XCTAssertEqual(mock.currentBuffer.contents, "Hello, World!")
  }

  func testBasicWithEnvironment() throws {
    let channel = try env.openChannel(name: "test")

    let called = expectation(description: "Callback is called")
    channel.withEnvironment {
      _ in called.fulfill()
    }
    waitForExpectations(timeout: 3)
  }

  func testOrderOfExecution() throws {
    let channel = try env.openChannel(name: "test")

    var calls: [Int] = []
    for i in 0 ..< 10 {
      let called = expectation(description: "Callback #\(i) is called")
      channel.withEnvironment {
        _ in
        calls.append(i)
        called.fulfill()
      }
    }
    waitForExpectations(timeout: 3)
    XCTAssertEqual(calls, [Int](0 ..< 10))
  }

  func testInTask() throws {
    let channel = try env.openChannel(name: "test")

    let called = expectation(description: "Callback is called")
    Task {
      channel.withEnvironment {
        _ in called.fulfill()
      }
    }
    waitForExpectations(timeout: 3)
  }

  func testInThread() throws {
    let channel = try env.openChannel(name: "test")

    let called = expectation(description: "Callback is called")
    DispatchQueue.global(qos: .background).async {
      channel.withEnvironment {
        _ in called.fulfill()
      }
    }
    waitForExpectations(timeout: 3)
  }

  func testUseEnvironment() throws {
    let channel = try env.openChannel(name: "test")
    try env.defun("42") {
      42
    }

    let called = expectation(description: "Callback is called")
    channel.withEnvironment {
      ownEnv in
      XCTAssertEqual(try ownEnv.funcall("42") as Int, 42)
      called.fulfill()
    }
    waitForExpectations(timeout: 3)
  }

  func testBufferSwitch() throws {
    let currentBuffer: String = try env.funcall("generate-new-buffer", with: "test")
    try env.funcall("set-buffer", with: currentBuffer)
    try env.funcall("insert", with: "Hello, World")
    XCTAssertEqual(try env.funcall("current-buffer"), currentBuffer)
    XCTAssertEqual(mock.currentBuffer.contents, "Hello, World")

    let channel = try env.openChannel(name: "test")

    let called = expectation(description: "Callback is called")
    channel.withEnvironment {
      _ in called.fulfill()
    }
    waitForExpectations(timeout: 3)
    XCTAssertEqual(try env.funcall("current-buffer"), currentBuffer)
    XCTAssertEqual(mock.currentBuffer.contents, "Hello, World")
  }

  func testSwiftCallback() throws {
    try env.defun("42") {
      42
    }

    var result = 0
    let channel = try env.openChannel(name: "test")
    let called = expectation(description: "Callback is called")

    let callback = channel.callback {
      (env: Environment, a: Int, b: Int, c: Int) in
      result = try a + b + c + env.funcall("42")
      called.fulfill()
    }

    callback(1, 2, 3)

    waitForExpectations(timeout: 3)

    XCTAssertEqual(result, 48)
  }

  func testLispCallback() throws {
    let called = expectation(description: "Callback is called")
    var result = 0

    let lispCallback = try env.defun {
      (x: Int, y: Int, z: Int) in
      result = x + y + z
      called.fulfill()
    }

    let channel = try env.openChannel(name: "test")

    let callback: (Int, Int, Int) -> Void = channel.callback(lispCallback)

    callback(1, 2, 3)

    waitForExpectations(timeout: 3)

    XCTAssertEqual(result, 6)
  }

  func testAsync() async throws {
    try env.defun("func") {
      (x: Int, y: Int, z: Int) in x + y + z
    }

    let channel = try env.openChannel(name: "test")

    let result: Int = try await channel.withAsyncEnvironment {
      env in try env.funcall("func", with: 1, 2, 3)
    }

    XCTAssertEqual(result, 6)
  }

  func testAsyncException() async throws {
    let channel = try env.openChannel(name: "test")

    let result: Int? = try? await channel.withAsyncEnvironment {
      env in try env.funcall("func", with: 1, 2, 3)
    }

    XCTAssertNil(result)
  }

  func testMultipleParallelChannels() async throws {
    let NUMBER_OF_CHANNELS = 5
    let NUMBER_OF_TASKS_PER_CHANNEL = 10

    actor CallsCollector {
      var calls: [[Int]]

      init(size: Int) {
        calls = Array(repeating: [], count: size)
      }

      func registerCall(channel: Int, task: Int) {
        calls[channel].append(task)
      }
    }

    let collector = CallsCollector(size: NUMBER_OF_CHANNELS)

    try await withThrowingTaskGroup(of: Void.self) {
      group in
      for i in 0 ..< NUMBER_OF_CHANNELS {
        let channel = try env.openChannel(name: "test\(i)")
        for j in 0 ..< NUMBER_OF_TASKS_PER_CHANNEL {
          group.addTask {
            let result = try await channel.withAsyncEnvironment {
              _ in j
            }
            await collector.registerCall(channel: i, task: result)
          }
        }
      }
    }

    for i in 0 ..< NUMBER_OF_CHANNELS {
      let calls = await collector.calls[i]
      // We don't know the exact order in which Tasks will get executed and, thus,
      // the order of indices in `calls`. We can, however, assert that all of them
      // truly happened.
      XCTAssertEqual(calls.sorted(), [Int](0 ..< NUMBER_OF_TASKS_PER_CHANNEL))
    }
  }

  func testNestedCallbacks() throws {
    let channel = try env.openChannel(name: "test")
    let called = expectation(description: "Callback is called")

    Task {
      channel.withEnvironment {
        _ in Task {
          channel.withEnvironment {
            _ in Task {
              channel.withEnvironment {
                _ in called.fulfill()
              }
            }
          }
        }
      }
    }

    waitForExpectations(timeout: 3)
  }

  func testNormalHook() throws {
    let channel = try env.openChannel(name: "test")
    let called = expectation(description: "Callback is called")

    try env.defun("run-hooks") {
      (hook: Symbol) in
      XCTAssertEqual(hook.name, "normal-hook")
      called.fulfill()
    }

    let callback: () -> Void = channel.hook("normal-hook")
    callback()

    waitForExpectations(timeout: 3)
  }

  func testAbnormalHook() throws {
    let channel = try env.openChannel(name: "test")
    let called = expectation(description: "Callback is called")

    try env.defun("run-hook-with-args") {
      (hook: Symbol, arg: Int) in
      XCTAssertEqual(hook.name, "abnormal-hook")
      XCTAssertEqual(arg, 42)
      called.fulfill()
    }

    let callback: (Int) -> Void = channel.hook("abnormal-hook")
    callback(42)

    waitForExpectations(timeout: 3)
  }
}
