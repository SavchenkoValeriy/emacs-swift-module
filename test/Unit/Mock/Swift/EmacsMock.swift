import EmacsEnvMock
import EmacsModule
@testable import EmacsSwiftModule
import Foundation

private func toMockEnv(_ raw: UnsafeMutablePointer<emacs_env>) -> EnvironmentMock {
  Unmanaged<EnvironmentMock>.fromOpaque(raw.pointee.private_members.pointee.owner).takeUnretainedValue()
}

class StoredValue {
  public let pointer: UnsafeMutablePointer<emacs_value_tag>
  public let deallocator: () -> Void

  init(_ data: UnsafeMutablePointer<Box>) {
    pointer = UnsafeMutablePointer<emacs_value_tag>.allocate(capacity: 1)
    pointer.initialize(to: emacs_value_tag(data: data))
    deallocator = { [data] in
      data.pointee.finalize()
      data.deinitialize(count: 1)
      data.deallocate()
    }
  }

  init() {
    pointer = UnsafeMutablePointer<emacs_value_tag>.allocate(capacity: 1)
    pointer.initialize(to: emacs_value_tag(data: nil))
    deallocator = {}
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
  var finalizer: AnyFinalizer?

  init<T>(_ value: T, _ finalizer: Finalizer<T>? = nil) {
    type = T.self
    self.value = value
    if let finalizer {
      setFinalizer(finalizer)
    } else {
      self.finalizer = nil
    }
  }

  mutating func setFinalizer<T>(_ finalizer: @escaping Finalizer<T>) {
    self.finalizer = {
      toFinalize in
      finalizer(toFinalize as! T)
    }
  }

  func finalize() {
    if let finalizer {
      finalizer(value)
    }
  }
}

class Reference {
  var to: emacs_value

  init(_ to: emacs_value) {
    self.to = to
  }
}

typealias Function = ([emacs_value]) -> emacs_value

struct FunctionData {
  let function: Function
  let payload: RawOpaquePointer?
}

public class Buffer {
  public let name: String
  public var contents: String = ""
  public var position = 0

  init(name: String) {
    self.name = name
  }
}

typealias SearchResults = [(range: Range<String.Index>, match: String)]

func reSearchForward(pattern emacsPattern: String, in text: String, from startIndex: Int = 0) -> SearchResults {
  // Translate Emacs-style regex pattern to ICU regex pattern
  let icuPattern = emacsPattern
    .replacingOccurrences(of: "\\(", with: "(")
    .replacingOccurrences(of: "\\)", with: ")")
    .replacingOccurrences(of: "[[:digit:]]", with: "\\d")

  do {
    let regex = try NSRegularExpression(pattern: icuPattern)
    let startRangeIndex = text.index(text.startIndex, offsetBy: startIndex, limitedBy: text.endIndex) ?? text.endIndex
    let searchRange = NSRange(startRangeIndex ..< text.endIndex, in: text)

    if let match = regex.firstMatch(in: text, options: [], range: searchRange) {
      var results = [(range: Range<String.Index>, match: String)]()

      for i in 0 ..< match.numberOfRanges {
        let range = match.range(at: i)
        if let stringRange = Range(range, in: text) {
          let matchString = String(text[stringRange])
          results.append((stringRange, matchString))
        }
      }
      return results
    }
  } catch {
    print("Invalid regex: \(error)")
  }

  return []
}

public class EnvironmentMock {
  var raw = UnsafeMutablePointer<emacs_env>.allocate(capacity: 1)
  var data: [StoredValue] = []
  var symbols: [String: emacs_value] = [:]
  var dataMutex = Lock()
  var buffers = [Buffer(name: "*scratch*")]
  var currentBufferIndex = 0
  var bufferMutex = Lock()
  var searchResults: SearchResults = []
  var searchResultsMutex = Lock()

  var filterMutex = Lock()
  let filterQueue = DispatchQueue(label: "filterQueue", attributes: .concurrent)
  let filterGroup = DispatchGroup()

  var Nil: emacs_value {
    intern("nil")
  }

  public var currentBuffer: Buffer {
    buffers[currentBufferIndex]
  }

  func findBuffer(named bufferName: String) -> Int? {
    buffers.firstIndex { $0.name == bufferName }
  }

  var interrupted = false
  var signaled = false
  var thrown = false

  public func interrupt() { dataMutex.locked { interrupted = true } }
  public func signal() { dataMutex.locked { signaled = true } }
  public func throwException() { dataMutex.locked { thrown = true } }

  func tag(_ pointer: UnsafeMutablePointer<Box>) -> UnsafeMutablePointer<emacs_value_tag> {
    dataMutex.locked {
      let result = StoredValue(pointer)
      data.append(result)
      return result.pointer
    }
  }

  func intern(_ name: String) -> emacs_value {
    if let symbol = dataMutex.locked({ symbols[name] }) {
      return symbol
    }

    return intern(name, with: dataMutex.locked { data[0].pointer })
  }

  func intern(_ name: String, with value: emacs_value) -> emacs_value {
    let symbol = make(Reference(value))
    dataMutex.locked { symbols[name] = symbol }
    return symbol
  }

  func extractFunction(_ value: emacs_value) -> FunctionData? {
    if let functionRef: Reference = extract(value, fatal: false),
       functionRef.to.pointee.data != nil,
       let function: FunctionData = extract(functionRef.to, fatal: false) {
      return function
    }
    if let function: FunctionData = extract(value) {
      return function
    }
    return nil
  }

  func funcall(_ rawFunction: emacs_value, _ count: CLong, _ args: UnsafePointer<emacs_value?>) -> emacs_value {
    guard let function = extractFunction(rawFunction) else {
      return Nil
    }
    return args.withMemoryRebound(to: emacs_value.self, capacity: count) {
      nonOptArgs in
      function.function(Array(UnsafeBufferPointer(start: nonOptArgs, count: count)))
    }
  }

  func make<T>(_ from: T, _ finalizer: Box.Finalizer<T>? = nil) -> emacs_value {
    let pointer = UnsafeMutablePointer<Box>.allocate(capacity: 1)
    pointer.initialize(to: Box(from, finalizer))
    return tag(pointer)
  }

  func make(_ from: String, _: Box.Finalizer<String>? = nil) -> emacs_value {
    if let cString = from.cString(using: .utf8) {
      return make(cString)
    }
    signal()
    return Nil
  }

  func make(_ str: UnsafePointer<CChar>, _ len: Int) -> emacs_value {
    let buffer = UnsafeBufferPointer(start: str, count: len + 1)
    var array = Array(buffer)
    array[len] = 0
    return make(array)
  }

  func box(of value: emacs_value) -> UnsafeMutablePointer<Box> {
    value.pointee.data.assumingMemoryBound(to: Box.self)
  }

  func extract<T>(_ value: emacs_value, fatal: Bool = true) -> T? {
    let box = box(of: value).pointee
    let result = box.value as? T
    if result == nil, fatal {
      // TODO: signal wrong types
      signal()
    }
    return result
  }

  func extract(_ value: emacs_value, fatal _: Bool = true) -> String? {
    if let array: [CChar] = extract(value) {
      return String(cString: array)
    }
    return nil
  }

  func extract(_ value: emacs_value, _ buf: UnsafeMutablePointer<CChar>?, _ len: UnsafeMutablePointer<Int>) -> Bool {
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
      raw in
      let env = toMockEnv(raw!)
      if env.signaled {
        return emacs_funcall_exit_signal
      }
      if env.thrown {
        return emacs_funcall_exit_throw
      }
      return emacs_funcall_exit_return
    }
    env.non_local_exit_get = {
      raw, symbol, data in
      let env = toMockEnv(raw!)
      if env.signaled {
        symbol!.pointee = env.intern("mock-signal")
        data!.pointee = env.Nil
        return emacs_funcall_exit_signal
      }
      if env.thrown {
        symbol!.pointee = env.intern("mock-exception")
        data!.pointee = env.Nil
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
    env.non_local_exit_signal = {
      raw, _, _ in
      toMockEnv(raw!).signal()
    }
    env.non_local_exit_throw = {
      raw, _, _ in
      toMockEnv(raw!).throwException()
    }
    env.intern = {
      raw, cString in
      toMockEnv(raw!).intern(String(cString: cString!))
    }
    env.is_not_nil = {
      raw, value in
      toMockEnv(raw!).Nil != value!
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
    env.make_unibyte_string = env.make_string
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
      return env.Nil
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
    env.make_function = {
      raw, min, max, function, _, payload in
      toMockEnv(raw!).make(
        FunctionData(function: {
          (args: [emacs_value]) in
          var mutableArgs = args
          return mutableArgs.withUnsafeMutableBufferPointer {
            argsPtr in
            let env = toMockEnv(raw!)
            if min > args.count || max < args.count {
              env.signal()
              return env.Nil
            }
            let rawPtr = UnsafeMutableRawPointer(argsPtr.baseAddress)
            let ptrToOpt = rawPtr?.bindMemory(to: emacs_value?.self, capacity: args.count)
            return function!(raw, args.count, ptrToOpt, payload)!
          }
        }, payload: payload)
      )
    }
    env.set_function_finalizer = {
      raw, function, finalizer in
      let env = toMockEnv(raw!)
      let box = env.box(of: function!)
      box.pointee.setFinalizer {
        (data: FunctionData) in
        if data.payload != nil {
          finalizer!(data.payload)
        }
      }
    }
    env.open_channel = {
      raw, value in
      if let fd: Int32 = toMockEnv(raw!).extract(value!) {
        return fd
      } else {
        toMockEnv(raw!).signal()
        return 0
      }
    }

    let nilValue: Int? = nil
    _ = intern("nil", with: make(nilValue))

    initializeBuiltins()

    env.private_members = UnsafeMutablePointer<emacs_env_private>.allocate(capacity: 1)
    env.private_members.initialize(to: emacs_env_private(owner: Unmanaged.passUnretained(self).toOpaque()))

    raw.initialize(from: &env, count: 1)
  }

  func bind(_ name: String, to function: @escaping Function) {
    _ = intern(name, with: make(FunctionData(function: function, payload: nil)))
  }

  func bindLocked(_ name: String, with mutex: Lock, to function: @escaping Function) {
    bind(name) { [unowned mutex] args in mutex.locked { function(args) } }
  }

  deinit {
    // First we ensure that all channels captured by closures
    // are deallocated.
    data = []
    // Then we wait for all pipes to get closed.
    filterGroup.wait()
    raw.pointee.private_members.deallocate()
    raw.deallocate()
  }

  public var environment: Environment {
    Environment(from: raw)
  }
}
