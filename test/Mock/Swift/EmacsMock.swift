import EmacsModule
import EmacsEnvMock
@testable import EmacsSwiftModule
import Foundation

fileprivate func toMockEnv(_ raw: UnsafeMutablePointer<emacs_env>) -> EnvironmentMock {
  return Unmanaged<EnvironmentMock>.fromOpaque(raw.pointee.private_members.pointee.owner).takeUnretainedValue()
}

class StoredValue<T> {
  public let pointer: UnsafeMutablePointer<emacs_value_tag>

  required init(_ pointer: UnsafeMutablePointer<T>) {
    self.pointer = UnsafeMutablePointer<emacs_value_tag>.allocate(capacity: 1)
    self.pointer.initialize(to: emacs_value_tag(data: pointer))
  }

  deinit {
    pointer.pointee.data.assumingMemoryBound(to: T.self).deallocate()
    pointer.deallocate()
  }
}

public class EnvironmentMock {
  var raw = UnsafeMutablePointer<emacs_env>.allocate(capacity: 1)
  var data: [AnyObject] = []

  func tag<T>(_ pointer: UnsafeMutablePointer<T>) -> UnsafeMutablePointer<emacs_value_tag> {
    let result = StoredValue(pointer)
    data.append(result)
    return result.pointer
  }

  fileprivate func make(_ from: Int) -> emacs_value {
    let pointer = UnsafeMutablePointer<Int>.allocate(capacity: 1)
    pointer.initialize(to: from)
    return tag(pointer)
  }

  fileprivate func make(_ str: UnsafePointer<CChar>, _ len: Int) -> emacs_value {
    let pointer = UnsafeMutablePointer<CChar>.allocate(capacity: len + 1)
    pointer.initialize(from: str, count: len)
    pointer.advanced(by: len).initialize(to: 0)
    return tag(pointer)
  }

  fileprivate func extract(_ value: emacs_value) -> Int {
    return value.pointee.data.assumingMemoryBound(to: Int.self).pointee
  }

  fileprivate func extract(_ value: emacs_value, _ buf: UnsafeMutablePointer<CChar>?, _ len: UnsafeMutablePointer<Int>) -> Bool {
    if buf == nil {
      let actualLen = strlen(value.pointee.data.assumingMemoryBound(to: CChar.self)) + 1
      len.initialize(to: actualLen)
    } else {
      let actualLen = len.pointee
      buf!.initialize(from: value.pointee.data.assumingMemoryBound(to: CChar.self), count: actualLen)
    }

    return true
  }

  public required init() {
    var env = emacs_env()
    env.size = MemoryLayout<emacs_env_29>.size
    env.non_local_exit_check = {
      _ in return emacs_funcall_exit_return
    }
    env.non_local_exit_get = {
      _, _, _ in return emacs_funcall_exit_return
    }
    env.non_local_exit_clear = { _ in }
    env.should_quit = {
      _ in return false
    }
    env.make_integer = {
      raw, value in
      return toMockEnv(raw!).make(value)
    }
    env.extract_integer = {
      raw, value in
      return toMockEnv(raw!).extract(value!)
    }
    env.make_string = {
      raw, str, len in
      return toMockEnv(raw!).make(str!, len)
    }
    env.copy_string_contents = {
      raw, value, buf, len in
      return toMockEnv(raw!).extract(value!, buf, len!)
    }
    env.private_members = UnsafeMutablePointer<emacs_env_private>.allocate(capacity: 1)
    env.private_members.initialize(to: emacs_env_private(owner: Unmanaged.passUnretained(self).toOpaque()))

    raw.initialize(from: &env, count: 1)
  }

  deinit {
    raw.pointee.private_members.deallocate()
    raw.deallocate()
  }

  public var environment: Environment {
    return Environment(from: raw)
  }
}

