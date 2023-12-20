import EmacsModule
@testable import EmacsSwiftModule
import Foundation

extension EnvironmentMock {
  func initializeBuiltins() {
    initializeListBuiltins()
    initializeBufferBuiltins()
    initializeRegexBuiltins()
    initializeMiscBuiltins()
  }

  private func initializeListBuiltins() {
    bind("cons") {
      [unowned self] args in
      if args.count != 2 {
        signal()
        return intern("nil")
      }
      return make(ConsCell(car: args[0], cdr: args[1]))
    }
    bind("car") {
      [unowned self] args in
      if args.count == 1, let cons: ConsCell<emacs_value, emacs_value> = extract(args[0]) {
        return cons.car
      } else {
        signal()
        return intern("nil")
      }
    }
    bind("cdr") {
      [unowned self] args in
      if args.count == 1, let cons: ConsCell<emacs_value, emacs_value> = extract(args[0]) {
        return cons.cdr
      } else {
        signal()
        return intern("nil")
      }
    }
    bind("list") {
      [unowned self] args in
      var result: emacs_value = intern("nil")
      for element in args.reversed() {
        result = make(ConsCell(car: element, cdr: result))
      }
      return result
    }
  }

  private func initializeBufferBuiltins() {
    bind("generate-new-buffer-name") {
      [unowned self] args in
      guard args.count == 1 else {
        signal()
        return intern("nil")
      }
      return args[0]
    }
    bind("generate-new-buffer") {
      [unowned self] args in
      guard args.count == 1,
            let name: String = extract(args[0]) else {
        signal()
        return intern("nil")
      }
      buffers.append(Buffer(name: name))
      return args[0]
    }
    bind("current-buffer") {
      [unowned self] _ in
      make(currentBuffer.name)
    }
    bind("set-buffer") {
      [unowned self] args in
      if args.count == 1,
         let name: String = extract(args[0]),
         let index = findBuffer(named: name) {
        currentBufferIndex = index
      } else {
        signal()
      }
      return intern("nil")
    }
    bind("point-max") {
      [unowned self] _ in
      make(currentBuffer.contents.count + 1)
    }
    bind("goto-char") {
      [unowned self] args in
      if args.count == 1,
         let position: Int = extract(args[0]) {
        currentBuffer.position = position - 1
      } else {
        signal()
      }
      return intern("nil")
    }
    bind("insert") {
      [unowned self] args in
      if args.count == 1,
         let text: String = extract(args[0]) {
        let position = currentBuffer.contents.index(currentBuffer.contents.startIndex, offsetBy: currentBuffer.position)
        currentBuffer.contents.insert(contentsOf: text, at: position)
      } else {
        signal()
      }
      return intern("nil")
    }
    bind("delete-region") {
      [unowned self] args in
      if args.count == 2,
         let start: Int = extract(args[0]),
         let end: Int = extract(args[1]),
         start <= end {
        let base = currentBuffer.contents.startIndex
        let startIndex = currentBuffer.contents.index(base, offsetBy: start - 1)
        let endIndex = currentBuffer.contents.index(base, offsetBy: end)
        let oldPosition = currentBuffer.contents.index(base, offsetBy: currentBuffer.position)
        currentBuffer.contents.removeSubrange(startIndex ..< endIndex)

        if oldPosition >= startIndex, oldPosition < endIndex {
          currentBuffer.position = currentBuffer.contents.distance(from: base, to: startIndex)
        } else if oldPosition >= endIndex {
          currentBuffer.position -= currentBuffer.contents.distance(from: startIndex, to: endIndex)
        }

      } else {
        signal()
      }
      return intern("nil")
    }
  }

  private func initializeRegexBuiltins() {
    bind("re-search-forward") {
      [unowned self] args in
      guard args.count >= 1,
            let pattern: String = extract(args[0]) else {
        signal()
        return intern("nil")
      }
      searchResults = reSearchForward(pattern: pattern, in: currentBuffer.contents, from: currentBuffer.position)
      if searchResults.isEmpty {
        return intern("nil")
      } else {
        return intern("t")
      }
    }
    bind("match-string") {
      [unowned self] args in
      guard args.count == 1,
            let index: Int = extract(args[0]),
            index < searchResults.count else {
        signal()
        return intern("nil")
      }
      return make(searchResults[index].match)
    }
    bind("match-end") {
      [unowned self] args in
      guard args.count == 1,
            let index: Int = extract(args[0]),
            index < searchResults.count else {
        signal()
        return intern("nil")
      }
      return make(currentBuffer.contents.distance(from: currentBuffer.contents.startIndex, to: searchResults[index].range.upperBound))
    }
  }

  private func initializeMiscBuiltins() {
    bind("vector") {
      [unowned self] args in
      make(args)
    }
    bind("symbol-name") {
      [unowned self] args in
      if args.count == 1, let pair = symbols.first(where: { $0.value == args[0] }) {
        return make(pair.key, pair.key.count)
      } else {
        signal()
        return intern("nil")
      }
    }
    bind("fset") {
      [unowned self] args in
      if args.count == 2, let ref: Reference = extract(args[0]) {
        ref.to = args[1]
      } else {
        signal()
      }
      return intern("nil")
    }
    bind("define-error") {
      [unowned self] _ in
      intern("nil")
    }
    bind("make-pipe-process") {
      [unowned self] args in
      // Actually we should find the corresponding :arg symbols, but
      // since it's used only for channel testing, we can couple it
      // with the way Channel calls the function.
      guard args.count == 8,
            let filter: FunctionData = extractFunction(args[7])
      else {
        signal()
        return intern("nil")
      }
      let pipe = Pipe()

      Task {
        while true {
          let availableData = pipe.fileHandleForReading.availableData
          if !availableData.isEmpty {
            // Convert Data to String
            if let message = String(data: availableData, encoding: .utf8) {
              _ = filter.function([intern("nil"), make(message)])
            }
          } else {
            // No more data, break the loop
            break
          }
          // Sleep to yield time to other tasks and avoid tight looping
          try? await Task.sleep(nanoseconds: 1000) // 0.01 second
        }
      }

      return make(pipe.fileHandleForWriting.fileDescriptor)
    }
  }
}
