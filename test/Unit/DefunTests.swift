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
}
