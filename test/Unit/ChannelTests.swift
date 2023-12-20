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
}
