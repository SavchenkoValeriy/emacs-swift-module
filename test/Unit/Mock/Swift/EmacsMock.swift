//
// EmacsMock.swift
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
import EmacsEnvMock
import EmacsModule
@testable import EmacsSwiftModule
import Foundation

private func toMockEnv(_ raw: UnsafeMutablePointer<emacs_env>) -> EnvironmentMock {
  Unmanaged<EnvironmentMock>.fromOpaque(raw.pointee.private_members.pointee.owner).takeUnretainedValue()
}

public class Buffer {
  public let name: String
  public var contents: String = ""
  public var position = 0

  init(name: String) {
    self.name = name
  }
}

public class EnvironmentMock {
  // Raw pointer to the object that we expose as the real Emacs environment pointer
  var raw = UnsafeMutablePointer<emacs_env>.allocate(capacity: 1)
  // All environment-controlled values.
  var data: [StoredValue] = []
  // The mapping from symbol name to its value.
  var symbols: [String: emacs_value] = [:]
  // Lock to ensure exclusive access to data and symbols.
  var dataMutex = Lock()
  // The list of open mock buffers.
  var buffers = [Buffer(name: "*scratch*")]
  // The index of the currently selected buffer.
  var currentBufferIndex = 0
  // Lock protecting from races over buffers and their states.
  var bufferMutex = Lock()
  // Current search results (see `re-search-forward`).
  var searchResults: SearchResults = []
  // Lock protecting search results from races.
  var searchResultsMutex = Lock()

  // Filters are special threads running to call filter functions over pipes.
  // This group of fields ensures that we call one filter at a time and that
  // filters stop working before we kill this environment.
  var filterMutex = Lock()
  let filterQueue = DispatchQueue(label: "filterQueue", attributes: .concurrent)
  let filterGroup = DispatchGroup()

  var Nil: emacs_value {
    intern("nil")
  }

  // Currently selected mock buffer.
  public var currentBuffer: Buffer {
    buffers[currentBufferIndex]
  }

  // Find buffer index for the buffer with the given name.
  func findBuffer(named bufferName: String) -> Int? {
    buffers.firstIndex { $0.name == bufferName }
  }

  // Emacs has been interrupted, i.e. the user pressed C-g.
  var interrupted = false
  // Emacs signaled an error.
  var signaled = false
  // Emacs threw an exception.
  var thrown = false

  // Interrupt Emacs.
  public func interrupt() { dataMutex.locked { interrupted = true } }
  // Signal Emacs error.
  public func signal() { dataMutex.locked { signaled = true } }
  // Throw Emacs exception.
  public func throwException() { dataMutex.locked { thrown = true } }

  // tag the given pointer and persist it in the current environment.
  func tag(_ pointer: UnsafeMutablePointer<Box>) -> UnsafeMutablePointer<emacs_value_tag> {
    dataMutex.locked {
      let result = StoredValue(pointer)
      data.append(result)
      return result.pointer
    }
  }

  // Intern the given name and return the corresponding symbol value.
  func intern(_ name: String) -> emacs_value {
    if let symbol = dataMutex.locked({ symbols[name] }) {
      return symbol
    }

    return intern(name, with: dataMutex.locked { data[0].pointer })
  }

  // Intern the given name with the given value and return the new symbol value.
  func intern(_ name: String, with value: emacs_value) -> emacs_value {
    let symbol = make(Reference(value))
    dataMutex.locked { symbols[name] = symbol }
    return symbol
  }

  // Extract function data from the given value if possible
  func extractFunction(_ value: emacs_value) -> FunctionData? {
    // It is either a reference to FunctionData...
    if let functionRef: Reference = extract(value, fatal: false),
       functionRef.to.pointee.data != nil,
       let function: FunctionData = extract(functionRef.to, fatal: false) {
      return function
    }
    // ...or straight up FunctionData (if it's a lambda).
    if let function: FunctionData = extract(value) {
      return function
    }
    return nil
  }

  // Replication of the environment API function doing `funcall`.
  func funcall(_ rawFunction: emacs_value, _ count: CLong, _ args: UnsafePointer<emacs_value?>) -> emacs_value {
    guard let function = extractFunction(rawFunction) else {
      return Nil
    }
    return args.withMemoryRebound(to: emacs_value.self, capacity: count) {
      nonOptArgs in
      function.function(Array(UnsafeBufferPointer(start: nonOptArgs, count: count)))
    }
  }

  // Box the given value and associate it with the given finalizer (if non-nil).
  // Lifetime of the new family of heap-allocated data is tied to the lifetime
  // of this environment.
  func make<T>(_ from: T, _ finalizer: Box.Finalizer<T>? = nil) -> emacs_value {
    let pointer = UnsafeMutablePointer<Box>.allocate(capacity: 1)
    pointer.initialize(to: Box(from, finalizer))
    return tag(pointer)
  }

  // make<T> override for String.
  func make(_ from: String, _: Box.Finalizer<String>? = nil) -> emacs_value {
    // To make it consistent with all the use-cases and standard APIs, we should
    // persist strings as C-string pointers.
    if let cString = from.cString(using: .utf8) {
      return make(cString)
    }
    signal()
    return Nil
  }

  // Replication of the `make_string` API.
  func make(_ str: UnsafePointer<CChar>, _ len: Int) -> emacs_value {
    let buffer = UnsafeBufferPointer(start: str, count: len + 1)
    var array = Array(buffer)
    // To be a proper C-string, it should be NULL-terminated.
    array[len] = 0
    // We box it simply as [CChar].
    return make(array)
  }

  // Extract a pointer to the underlying box of the value.
  func box(of value: emacs_value) -> UnsafeMutablePointer<Box> {
    // All emacs_values produced by the environment should have
    // boxes under the hood.
    value.pointee.data.assumingMemoryBound(to: Box.self)
  }

  // Extract the value of the given type from an opaque mock emacs_value.
  func extract<T>(_ value: emacs_value, fatal: Bool = true) -> T? {
    let box = box(of: value).pointee
    let result = box.value as? T
    if result == nil, fatal {
      // TODO: signal wrong types
      signal()
    }
    return result
  }

  // Override for extract<T> for String.
  func extract(_ value: emacs_value, fatal _: Bool = true) -> String? {
    // We never store strings as String, but as [CChar].
    if let array: [CChar] = extract(value) {
      return String(cString: array)
    }
    return nil
  }

  // Replication of the `copy_string_contents` API.
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

  // Bind the given closure under the given name.
  func bind(_ name: String, to function: @escaping Function) {
    _ = intern(name, with: make(FunctionData(function: function, payload: nil)))
  }

  // Bind the given closure under the given name and lock the mutex.
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
