//
// Channel.swift
// Copyright (C) 2022 Valeriy Savchenko
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
import Foundation

#if os(macOS)
  import os.lock
#endif

#if os(macOS)
  typealias Lock = os_unfair_lock_s
  private func makeLock() -> Lock { os_unfair_lock() }
  private func lock(_ lock: inout Lock) { os_unfair_lock_lock(&lock) }
  private func unlock(_ lock: inout Lock) { os_unfair_lock_unlock(&lock) }
#else
  typealias Lock = NSLock
  private func makeLock() -> Lock { NSLock() }
  private func lock(_ lock: inout Lock) { lock.lock() }
  private func unlock(_ lock: inout Lock) { lock.unlock() }
#endif

typealias Callback = (Environment) throws -> Void

private struct CallbackStack {
  typealias Index = Int

  private var callbacks: [Callback?] = []
  private var mutex = makeLock()

  mutating func push(callback: @escaping Callback) -> Index {
    lock(&mutex)
    defer { unlock(&mutex) }

    callbacks.append(callback)
    return callbacks.count - 1
  }

  mutating func pop(at index: Index) -> Callback? {
    lock(&mutex)
    defer { unlock(&mutex) }

    guard let callback = callbacks[index] else {
      print("Tried to call already called callback!")
      return nil
    }

    callbacks[index] = nil
    if callbacks.allSatisfy({ $0 == nil }) {
      callbacks.removeAll()
    }

    return callback
  }
}

/// A communication channel that can be used at all times.
///
/// While ``Environment`` is available when Emacs actively calls
/// into a module code, we might still want to ping Emacs from
/// the Swift side and have an asynchronous callback, for example.
///
/// `Channel` allows exactly that. After opening a channel via
/// ``Environment/openChannel(name:)``, it maintains a live connection
/// to Emacs runtime.
///
/// See <doc:AsyncCallbacks> for more detail.
public class Channel {
  // Emacs doesn't allow dynamic modules to keep their environments,
  // and the only thing that is allowed is to signal Emacs somehowe
  // to call back into module-defined functions to get a new environment
  // and use it. One of such mechanisms is a "pipe process". The main
  // idea there being that the module code writes to this pipe
  // and Emacs Lisp handler that opened this pipe will get notified
  // at some point that new data is available. This handler can call
  // some other functions making it possible to emulate a callback
  // through that.
  //
  // Channel takes this approach and hides it entirely from the users.
  // It creates a "pipe process" itself, defines a logic for handling
  // updates while capturing itself in that function. When it's time
  // to call a callback, it pushes the callback onto the stack together
  // with the arguments for the call, and writes the index on the stack
  // into the pipe. When it is finally read on the Emacs side, while
  // still being in a Swift-defined code, we read that index and call
  // the call by its index.

  /// A name of the channel for easier identification.
  public let name: String
  /// This is an actual pipe opened by the Emacs for us, so we can
  /// communicate asynchronously with our "agent" function on the
  /// Emacs side.
  private var pipe: FileHandle?
  /// This is our internal thread-safe data-structure to keep track
  /// of all registered calls and their arguments.
  private var stack = CallbackStack()

  // We need a lock to prevent races writing to the pipe.
  private var mutex = makeLock()

  fileprivate init(name: String) {
    self.name = name
  }

  fileprivate func setFileDescriptor(_ fileDescriptor: Int32) {
    pipe = FileHandle(fileDescriptor: fileDescriptor)
  }

  deinit {
    // Let's not forget to close the pipe, it's actually our
    // responsibility
    try? pipe?.close()
  }

  /// Call the callback stored under the given index.
  private func call(_ index: CallbackStack.Index, with env: Environment) throws {
    if let callback = stack.pop(at: index) {
      try callback(env)
    }
  }

  /// Register a callback to be called with the given arguments.
  func register(callback: @escaping Callback) {
    write(stack.push(callback: callback))
  }

  private func write(_ index: CallbackStack.Index) {
    lock(&mutex)
    defer { unlock(&mutex) }

    if let data = "\(index)\n".data(using: String.Encoding.utf8) {
      do {
        if #available(macOS 10.15.4, *) {
          try pipe?.write(contentsOf: data)
        } else {
          pipe?.write(data)
        }
      } catch {
        fatalError("Error writing to a pipe")
      }
    }
  }

  // This is the function that makes everything happen on the Emacs side
  // controlling the pipe process.
  fileprivate func makeProcess(in env: Environment) throws -> EmacsValue {
    let bufferName: String = try env.funcall(
      "generate-new-buffer-name", with: " swift-channel-\(name)"
    )
    let buffer = try env.funcall("generate-new-buffer", with: bufferName)

    let filter = try env.defun {
      [self] (env: Environment, _: EmacsValue, message: EmacsValue) throws
      in
      // As of now, I don't know how to use Emacs Lisp macros in
      // dynamic modules, so instead of (with-current-buffer ...),
      // we need to manually do everything it does.
      let currentBuffer = try env.funcall("current-buffer")
      // Usually the way to go would be to call (process-buffer process),
      // but we actually know the buffer name from earlier in the outer
      // function.
      try env.funcall("set-buffer", with: bufferName)
      // First, let's insert the newly received message from the pipe.
      try env.funcall("goto-char", with: env.funcall("point-max"))
      try env.funcall("insert", with: message)
      // Then go back to the beginning of the buffer (it should contain
      // only data about the functions we still need to call).
      try env.funcall("goto-char", with: 1)
      // While we match our callback stack indices, we proceed.
      while try env.funcall(
        "re-search-forward", with: "\\([[:digit:]]+\\)\n",
        env.Nil, env.t
      ) {
        let indexStr: String = try env.funcall("match-string", with: 1)
        try env.funcall(
          "delete-region", with: 1, env.funcall("match-end", with: 0)
        )
        guard let index = Int(indexStr) else {
          fatalError("Found unexpected match in the channel!")
        }

        // The main part is here, we are capturing self and can
        // `call` our callback from here.
        //
        // It is very important to call functions on exactly the
        // same thread this filter was called.
        try call(index, with: env)
      }
      try env.funcall("set-buffer", with: currentBuffer)
    }
    // In order to make a pipe process, we need two main things:
    //   * a buffer
    //   * a filter function
    return try env.funcall(
      "make-pipe-process", with: Symbol(name: ":name"), name,
      Symbol(name: ":noquery"), true, Symbol(name: ":buffer"), buffer,
      Symbol(name: ":filter"),
      filter
    )
  }
}

public extension Environment {
  /// Open a communication channel with Emacs for the time when Environment is not available.
  ///
  /// The only way to communicate back to Emacs and call back
  /// into Emacs is to open a channel. Channels don't have any
  /// lifetime restrictions associated with environments.
  /// For more details, see <doc:AsyncCallbacks> and ``Channel``.
  ///
  /// - Parameter name: the name to identify the channel.
  /// - Returns: a new communication channel with the given name.
  /// - Throws: an ``EmacsError`` if something goes wrong.
  func openChannel(name: String) throws -> Channel {
    // Please see Channel comments for additional information
    // on the dark magic happening here.
    if version < .Emacs28 {
      throw EmacsError.unsupported(
        what: "channels are only available for Emacs 28 and later")
    }
    let channel = Channel(name: name)
    let pipeFD = try pointee.open_channel(
      raw, channel.makeProcess(in: self).raw
    )
    channel.setFileDescriptor(pipeFD)
    return channel
  }
}
