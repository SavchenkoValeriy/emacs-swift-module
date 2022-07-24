import Foundation

protocol AnyLazyCallback {
  func call(_ env: Environment, with args: Any) throws
}

struct CallbackStack {
  typealias Element = (callback: AnyLazyCallback, args: Any)
  typealias Index = Int
  var elements: [Element?] = []

  mutating func push(callback: AnyLazyCallback, args: Any) -> Index {
    elements.append((callback, args))
    return elements.count - 1
  }

  mutating func pop(at index: Index, with env: Environment) {
    guard let element = elements[index] else {
      print("Tried to call already called element!")
      return
    }
    do {
      try element.callback.call(env, with: element.args)
    } catch {
      print("Callback encountered error: \(error)")
    }
    elements[index] = nil
    if elements.allSatisfy({ $0 == nil }) {
      elements.removeAll()
    }
  }
}

public class Channel {
  public let name: String
  private var pipe: FileHandle? = nil
  var stack = CallbackStack()

  init(name: String) {
    self.name = name
  }

  fileprivate func setFileDescriptor(_ fileDescriptor: Int32) {
    self.pipe = FileHandle(fileDescriptor: fileDescriptor)
  }

  private func call(_ index: Int, with env: Environment) {
    stack.pop(at: index, with: env)
  }

  func write(_ message: String) {
    if let data = message.data(using: String.Encoding.utf8) {
      do {
        try pipe?.write(contentsOf: data)
      } catch {
        fatalError("Error writing to a pipe")
      }
    }
  }

  fileprivate func makeProcess(in env: Environment) throws -> EmacsValue {
    let bufferName: String = try env.funcall(
      "generate-new-buffer-name", with: " swift-channel-\(name)")
    let buffer = try env.funcall("generate-new-buffer", with: bufferName)

    let filter = try env.defun {
      [self] (env: Environment, process: EmacsValue, message: EmacsValue) throws
      in
      let currentBuffer = try env.funcall("current-buffer")
      try env.funcall("set-buffer", with: bufferName)
      try env.funcall("goto-char", with: try env.funcall("point-max"))
      try env.funcall("insert", with: message)
      try env.funcall("goto-char", with: 1)
      while try env.funcall(
        "re-search-forward", with: "\\([[:digit:]]+\\):\\([[:alpha:]]+\\)\n",
        env.Nil, env.t)
      {
        let indexStr: String = try env.funcall("match-string", with: 1)
        guard let index = Int(indexStr) else {
          fatalError("Found unexpected match in the channel!")
        }
        call(index, with: env)
        try env.funcall(
          "delete-region", with: 1, try env.funcall("match-end", with: 0))
      }
      try env.funcall("set-buffer", with: currentBuffer)
    }
    return try env.funcall(
      "make-pipe-process", with: Symbol(name: ":name"), name,
      Symbol(name: ":noquery"), true, Symbol(name: ":buffer"), buffer,
      Symbol(name: ":filter"),
      filter)
  }
}

extension Environment {
  public func openChannel(name: String) throws -> Channel {
    let channel = Channel(name: name)
    let pipeFD = raw.pointee.open_channel(
      raw, try channel.makeProcess(in: self).raw)
    channel.setFileDescriptor(pipeFD)
    return channel
  }
}
