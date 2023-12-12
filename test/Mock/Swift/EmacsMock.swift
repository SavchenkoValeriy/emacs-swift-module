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
      if let box = data.pointee as? Box {
        box.finalize()
      }
      data.deinitialize(count: 1)
      data.deallocate()
    }
  }

  deinit {
    deallocator()
    pointer.deallocate()
  }
}

struct Box {
  typealias Finalizer<T> = (T) -> Void
  typealias AnyFinalizer = Finalizer<Any>

  let type: Any.Type
  let value: Any
  let finalizer: AnyFinalizer?

  init<T>(_ value: T, _ finalizer: Finalizer<T>? = nil) {
    type = T.self
    self.value = value
    if let finalizer {
      self.finalizer = {
        toFinalize in
        finalizer(toFinalize as! T)
      }
    } else {
      self.finalizer = nil
    }
  }

  func finalize() {
    if let finalizer {
      finalizer(value)
    }
  }
}

public class EnvironmentMock {
  typealias Function = ([emacs_value]) -> emacs_value
  var raw = UnsafeMutablePointer<emacs_env>.allocate(capacity: 1)
  var data: [StoredValue] = []
  var symbols: [String: emacs_value] = [:]

  var interrupted = false
  var signaled = false
  var thrown = false

  func interrupt() { interrupted = true }
  func signal() { signaled = true }
  func throwException() { thrown = true }

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
    guard let functionIndex: Int = extract(rawFunction) else {
      return intern("nil")
    }
    guard let function: Function = extract(data[functionIndex].pointer) else {
      return intern("nil")
    }
    return args.withMemoryRebound(to: emacs_value.self, capacity: count) {
      nonOptArgs in
      function(Array(UnsafeBufferPointer(start: nonOptArgs, count: count)))
    }
  }

  private func make<T>(_ from: T, _ finalizer: Box.Finalizer<T>? = nil) -> emacs_value {
    let pointer = UnsafeMutablePointer<Box>.allocate(capacity: 1)
    pointer.initialize(to: Box(from, finalizer))
    return tag(pointer)
  }

  private func make(_ str: UnsafePointer<CChar>, _ len: Int) -> emacs_value {
    let buffer = UnsafeBufferPointer(start: str, count: len + 1)
    var array = Array(buffer)
    array[len] = 0
    return make(array)
  }

  private func extract<T>(_ value: emacs_value) -> T? {
    let box = value.pointee.data.assumingMemoryBound(to: Box.self).pointee
    let result = box.value as? T
    if result == nil {
      // TODO: signal wrong types
      signal()
    }
    return result
  }

  private func extract(_ value: emacs_value, _ buf: UnsafeMutablePointer<CChar>?, _ len: UnsafeMutablePointer<Int>) -> Bool {
    let array: [CChar] = extract(value) ?? []
    if buf == nil {
      len.initialize(to: array.count)
    } else {
      let actualLen = len.pointee
      buf!.initialize(from: array, count: actualLen)
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
      raw, symbol, data in
      let env = toMockEnv(raw!)
      if env.signaled {
        symbol!.pointee = env.intern("mock-signal")
        data!.pointee = env.intern("nil")
        return emacs_funcall_exit_signal
      }
      if env.thrown {
        symbol!.pointee = env.intern("mock-exception")
        data!.pointee = env.intern("nil")
        return emacs_funcall_exit_throw
      }
      return emacs_funcall_exit_return
    }
    env.non_local_exit_clear = {
      raw in
      let env = toMockEnv(raw!)
      env.interrupted = false
      env.signaled = false
      env.thrown = false
    }
    env.should_quit = {
      raw in toMockEnv(raw!).interrupted
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
      toMockEnv(raw!).extract(value!) ?? 0
    }
    env.make_float = {
      raw, value in
      toMockEnv(raw!).make(value)
    }
    env.extract_float = {
      raw, value in
      toMockEnv(raw!).extract(value!) ?? 0
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
      if let array: [emacs_value] = env.extract(value!) {
        return array[index]
      }
      return env.intern("nil")
    }
    env.vec_size = {
      raw, value in
      let env = toMockEnv(raw!)
      let array: [emacs_value]? = env.extract(value!)
      return array?.count ?? 0
    }
    env.make_user_ptr = {
      raw, finalizer, ptr in
      toMockEnv(raw!).make(ptr!, finalizer)
    }
    env.get_user_ptr = {
      raw, value in
      toMockEnv(raw!).extract(value!)
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
    bind("symbol-name") {
      [unowned self] args in
      if let pair = symbols.first(where: { $0.value == args[0] }) {
        make(pair.key, pair.key.count)
      } else {
        intern("nil")
      }
    }
    bind("cons") {
      [unowned self] args in
      make(ConsCell(car: args[0], cdr: args[1]))
    }
    bind("car") {
      [unowned self] args in
      if let cons: ConsCell<emacs_value, emacs_value> = extract(args[0]) {
        cons.car
      } else {
        intern("nil")
      }
    }
    bind("cdr") {
      [unowned self] args in
      if let cons: ConsCell<emacs_value, emacs_value> = extract(args[0]) {
        cons.cdr
      } else {
        intern("nil")
      }
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
