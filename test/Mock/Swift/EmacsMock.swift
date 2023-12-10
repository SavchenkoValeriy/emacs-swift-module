import EmacsEnvMock
import EmacsModule
@testable import EmacsSwiftModule
import Foundation

private func toMockEnv(_ raw: UnsafeMutablePointer<emacs_env>) -> EnvironmentMock {
  Unmanaged<EnvironmentMock>.fromOpaque(raw.pointee.private_members.pointee.owner).takeUnretainedValue()
}

class StoredValue {
  public let pointer: UnsafeMutablePointer<emacs_value_tag>
  public var deallocator: () -> Void

  convenience init(_ pointer: UnsafeMutablePointer<some Any>) {
    self.init()
    setq(pointer)
  }

  required init() {
    pointer = UnsafeMutablePointer<emacs_value_tag>.allocate(capacity: 1)
    pointer.initialize(to: emacs_value_tag(data: nil))
    deallocator = {}
  }

  public func setq(_ data: UnsafeMutablePointer<some Any>) {
    deallocator()
    pointer.update(repeating: emacs_value_tag(data: data), count: 1)
    deallocator = { [data] in
      data.deinitialize(count: 1)
      data.deallocate()
    }
  }

  deinit {
    deallocator()
    pointer.deallocate()
  }
}

public class EnvironmentMock {
  typealias Function = ([emacs_value]) -> emacs_value
  var raw = UnsafeMutablePointer<emacs_env>.allocate(capacity: 1)
  var data: [StoredValue] = []
  var symbols: [String: emacs_value] = [:]

  func tag(_ pointer: UnsafeMutablePointer<some Any>) -> UnsafeMutablePointer<emacs_value_tag> {
    let result = StoredValue(pointer)
    data.append(result)
    return result.pointer
  }

  func intern(_ name: String) -> emacs_value {
    if let symbol = symbols[name] {
      return symbol
    }

    let index = data.count
    data.append(StoredValue())
    let symbol = make(index)
    symbols[name] = symbol
    return symbol
  }

  func funcall(_ rawFunction: emacs_value, _ count: CLong, _ args: UnsafePointer<emacs_value?>) -> emacs_value {
    let functionIndex: Int = extract(rawFunction)
    let function: Function = extract(data[functionIndex].pointer)
    return args.withMemoryRebound(to: emacs_value.self, capacity: count) {
      nonOptArgs in
      function(Array(UnsafeBufferPointer(start: nonOptArgs, count: count)))
    }
  }

  private func make<T>(_ from: T) -> emacs_value {
    let pointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
    pointer.initialize(to: from)
    return tag(pointer)
  }

  private func make(_ str: UnsafePointer<CChar>, _ len: Int) -> emacs_value {
    let pointer = UnsafeMutablePointer<CChar>.allocate(capacity: len + 1)
    pointer.initialize(from: str, count: len)
    pointer.advanced(by: len).initialize(to: 0)
    return tag(pointer)
  }

  private func extract<T>(_ value: emacs_value) -> T {
    value.pointee.data.assumingMemoryBound(to: T.self).pointee
  }

  private func extract(_ value: emacs_value, _ buf: UnsafeMutablePointer<CChar>?, _ len: UnsafeMutablePointer<Int>) -> Bool {
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
      _ in emacs_funcall_exit_return
    }
    env.non_local_exit_get = {
      _, _, _ in emacs_funcall_exit_return
    }
    env.non_local_exit_clear = { _ in }
    env.should_quit = {
      _ in false
    }
    env.intern = {
      raw, cString in
      toMockEnv(raw!).intern(String(cString: cString!))
    }
    env.is_not_nil = {
      raw, value in
      UnsafeMutableRawPointer(toMockEnv(raw!).environment.Nil.raw!) != value!
    }
    env.make_integer = {
      raw, value in
      toMockEnv(raw!).make(value)
    }
    env.extract_integer = {
      raw, value in
      toMockEnv(raw!).extract(value!)
    }
    env.make_float = {
      raw, value in
      toMockEnv(raw!).make(value)
    }
    env.extract_float = {
      raw, value in
      toMockEnv(raw!).extract(value!)
    }
    env.make_string = {
      raw, str, len in
      toMockEnv(raw!).make(str!, len)
    }
    env.copy_string_contents = {
      raw, value, buf, len in
      toMockEnv(raw!).extract(value!, buf, len!)
    }
    env.vec_get = {
      raw, value, index in
      let env = toMockEnv(raw!)
      let array: [emacs_value] = env.extract(value!)
      return array[index]
    }
    env.vec_size = {
      raw, value in
      let env = toMockEnv(raw!)
      let array: [emacs_value] = env.extract(value!)
      return array.count
    }
    env.funcall = {
      raw, function, count, args in
      toMockEnv(raw!).funcall(function!, count, args!)
    }

    initializeBuiltins()

    env.private_members = UnsafeMutablePointer<emacs_env_private>.allocate(capacity: 1)
    env.private_members.initialize(to: emacs_env_private(owner: Unmanaged.passUnretained(self).toOpaque()))

    raw.initialize(from: &env, count: 1)
  }

  func bind(_ name: String, to function: @escaping Function) {
    let index = data.count
    _ = make(function)
    let symbol = make(index)
    symbols[name] = symbol
  }

  func initializeBuiltins() {
    bind("vector") {
      [unowned self] args in
      make(args)
    }
  }

  deinit {
    raw.pointee.private_members.deallocate()
    raw.deallocate()
  }

  public var environment: Environment {
    Environment(from: raw)
  }
}
