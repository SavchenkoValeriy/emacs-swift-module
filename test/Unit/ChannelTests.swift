import EmacsMock
@testable import EmacsSwiftModule
import XCTest

class ChannelTests: XCTestCase {
  func testBufferOps() throws {
    let mock = EnvironmentMock()
    let env = mock.environment
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
    let mock = EnvironmentMock()
    let env = mock.environment
    let channel = try env.openChannel(name: "test")

    let called = expectation(description: "Callback is called")
    channel.withEnvironment {
      _ in called.fulfill()
    }
    waitForExpectations(timeout: 3)
  }

  func testOrderOfExecution() throws {
    let mock = EnvironmentMock()
    let env = mock.environment
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
    let mock = EnvironmentMock()
    let env = mock.environment
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
    let mock = EnvironmentMock()
    let env = mock.environment
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
    let mock = EnvironmentMock()
    let env = mock.environment
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
    let mock = EnvironmentMock()
    let env = mock.environment
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
}
