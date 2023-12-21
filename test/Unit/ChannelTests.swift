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

  func testSwiftCallback() throws {
    let mock = EnvironmentMock()
    let env = mock.environment

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
    let mock = EnvironmentMock()
    let env = mock.environment

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
    let mock = EnvironmentMock()
    let env = mock.environment

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
    let mock = EnvironmentMock()
    let env = mock.environment

    let channel = try env.openChannel(name: "test")

    let result: Int? = try? await channel.withAsyncEnvironment {
      env in try env.funcall("func", with: 1, 2, 3)
    }

    XCTAssertNil(result)
  }

  func testMultipleParallelChannels() async throws {
    let mock = EnvironmentMock()
    let env = mock.environment

    let NUMBER_OF_CHANNELS = 5
    let NUMBER_OF_TASKS_PER_CHANNEL = 10

    var expectations: [XCTestExpectation] = []

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

    for i in 0 ..< NUMBER_OF_CHANNELS {
      let channel = try env.openChannel(name: "test\(i)")
      for j in 0 ..< NUMBER_OF_TASKS_PER_CHANNEL {
        expectations.append(expectation(description: "Callback #\(j) is called for the channel #\(i)"))
        let called = expectations.last!
        Task {
          _ = try await channel.withAsyncEnvironment {
            env in
            called.fulfill()
            return env.Nil
          }
          await collector.registerCall(channel: i, task: j)
        }
      }
    }

    await fulfillment(of: expectations, timeout: 3)
    for i in 0 ..< NUMBER_OF_CHANNELS {
      let calls = await collector.calls[i]
      // We don't know the exact order in which Tasks will get executed and, thus,
      // the order of indices in `calls`. We can, however, assert that all of them
      // truly happened.
      XCTAssertEqual(calls.sorted(), [Int](0 ..< NUMBER_OF_TASKS_PER_CHANNEL))
    }
  }
}
