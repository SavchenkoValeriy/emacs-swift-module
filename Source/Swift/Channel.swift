import Foundation
import os.lock

/// This is a callback that knows how to unpack its arguments and call itself
protocol AnyLazyCallback {
  /// Call this callback within the given environment.
  ///
  ///  - Parameters:
  ///    - env: Emacs Environment to make a call within.
  ///    - args: an opaque value containing all of the needed arguments.
  ///  - Throws: any exception that might occur during the call.
  func call(_ env: Environment, with args: Any) throws
}

struct CallbackStack {
  typealias Element = (callback: AnyLazyCallback, args: Any)
  typealias Index = Int
  private var elements: [Element?] = []
  private var lock = os_unfair_lock()

  mutating func push(callback: AnyLazyCallback, args: Any) -> Index {
    os_unfair_lock_lock(&lock)
    defer { os_unfair_lock_unlock(&lock) }

    elements.append((callback, args))
    return elements.count - 1
  }

  mutating func pop(at index: Index, with env: Environment) throws {
    os_unfair_lock_lock(&lock)
    defer { os_unfair_lock_unlock(&lock) }

    guard let element = elements[index] else {
      print("Tried to call already called element!")
      return
    }

    try element.callback.call(env, with: element.args)

    elements[index] = nil
    if elements.allSatisfy({ $0 == nil }) {
      elements.removeAll()
    }
  }
}

/// A communication channel that can be used at all times.
///
/// While `Environment` is available when Emacs actively calls
/// into a module code, we might still want to ping Emacs from
/// the Swift side and have an asynchronous callback, for example.
/// Channel allows exactly that. After opening a channel via
/// `Environment.openChannel(name:)`, it maintains a live connection
/// to Emacs runtime.
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
  private var pipe: FileHandle? = nil
  /// This is our internal thread-safe data-structure to keep track
  /// of all registered calls and their arguments.
  var stack = CallbackStack()

  // We need a lock to prevent races writing to the pipe.
  private var lock = os_unfair_lock()

  fileprivate init(name: String) {
    self.name = name
  }

  fileprivate func setFileDescriptor(_ fileDescriptor: Int32) {
    self.pipe = FileHandle(fileDescriptor: fileDescriptor)
  }

  deinit {
    // Let's not forget to close the pipe, it's actually our
    // responsibility
    try? pipe?.close()
  }

  /// Call the callback stored under the given index.
  private func call(_ index: Int, with env: Environment) throws {
    try self.stack.pop(at: index, with: env)
  }

  /// Register a callback to be called with the given arguments.
  func register(callback: AnyLazyCallback, args: Any) {
    write(stack.push(callback: callback, args: args))
  }

  private func write(_ index: Int) {
    os_unfair_lock_lock(&lock)
    defer { os_unfair_lock_unlock(&lock) }

    if let data = "\(index)\n".data(using: String.Encoding.utf8) {
      do {
        try pipe?.write(contentsOf: data)
      } catch {
        fatalError("Error writing to a pipe")
      }
    }
  }

  // This is the function that makes everything happen on the Emacs side
  // controlling the pipe process.
  fileprivate func makeProcess(in env: Environment) throws -> EmacsValue {
    let bufferName: String = try env.funcall(
      "generate-new-buffer-name", with: " swift-channel-\(name)")
    let buffer = try env.funcall("generate-new-buffer", with: bufferName)

    let filter = try env.defun {
      [self] (env: Environment, process: EmacsValue, message: EmacsValue) throws
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
      try env.funcall("goto-char", with: try env.funcall("point-max"))
      try env.funcall("insert", with: message)
      // Then go back to the beginning of the buffer (it should contain
      // only data about the functions we still need to call).
      try env.funcall("goto-char", with: 1)
      // While we match our calback stack indices, we proceed.
      while try env.funcall(
        "re-search-forward", with: "\\([[:digit:]]+\\)\n",
        env.Nil, env.t)
      {
        let indexStr: String = try env.funcall("match-string", with: 1)
        try env.funcall(
          "delete-region", with: 1, try env.funcall("match-end", with: 0))
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
      filter)
  }
}

extension Environment {
  /// Open a communication channel with Emacs for the time when Environment is not available.
  ///
  /// The only way to communicate back to Emacs and call back
  /// into Emacs is to open a channel. Channels don't have any
  /// lifetime restrictions associated with environments.
  /// For more details, see `Channel`.
  ///
  /// - Parameter name: the name to identify the channel.
  /// - Returns: a new communication channel with the given name.
  /// - Throws: an `EmacsError` if something goes wrong.
  public func openChannel(name: String) throws -> Channel {
    // Please see Channel comments for additional information
    // on the dark magic happening here.
    let channel = Channel(name: name)
    let pipeFD = raw.pointee.open_channel(
      raw, try channel.makeProcess(in: self).raw)
    channel.setFileDescriptor(pipeFD)
    return channel
  }
}
