//
// Builtins.swift
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
import EmacsModule
@testable import EmacsSwiftModule
import Foundation

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

// This module does not have a goal of reproducing every single builtin function
// available in Emacs Lisp. That would've been an extremely tedious and pointless
// work. Instead, we try to limit ourselves only to functions that we actually use
// to provide basic Swift module APIs.
//
// If you ever find the need to implement a new function, please, go ahead.
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
        return Nil
      }
      return make(ConsCell(car: args[0], cdr: args[1]))
    }
    bind("car") {
      [unowned self] args in
      if args.count == 1, let cons: ConsCell<emacs_value, emacs_value> = extract(args[0]) {
        return cons.car
      } else {
        signal()
        return Nil
      }
    }
    bind("cdr") {
      [unowned self] args in
      if args.count == 1, let cons: ConsCell<emacs_value, emacs_value> = extract(args[0]) {
        return cons.cdr
      } else {
        signal()
        return Nil
      }
    }
    bind("list") {
      [unowned self] args in
      var result: emacs_value = Nil
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
        return Nil
      }
      return args[0]
    }
    bindLocked("generate-new-buffer", with: bufferMutex) {
      [unowned self] args in
      guard args.count == 1,
            let name: String = extract(args[0]) else {
        signal()
        return Nil
      }
      buffers.append(Buffer(name: name))
      return args[0]
    }
    bindLocked("current-buffer", with: bufferMutex) {
      [unowned self] _ in
      make(currentBuffer.name)
    }
    bindLocked("set-buffer", with: bufferMutex) {
      [unowned self] args in
      if args.count == 1,
         let name: String = extract(args[0]),
         let index = findBuffer(named: name) {
        currentBufferIndex = index
      } else {
        signal()
      }
      return Nil
    }
    bindLocked("point-max", with: bufferMutex) {
      [unowned self] _ in
      make(currentBuffer.contents.count + 1)
    }
    bindLocked("goto-char", with: bufferMutex) {
      [unowned self] args in
      if args.count == 1,
         let position: Int = extract(args[0]) {
        currentBuffer.position = position - 1
      } else {
        signal()
      }
      return Nil
    }
    bindLocked("insert", with: bufferMutex) {
      [unowned self] args in
      if args.count == 1,
         let text: String = extract(args[0]) {
        let position = currentBuffer.contents.index(currentBuffer.contents.startIndex, offsetBy: currentBuffer.position)
        currentBuffer.contents.insert(contentsOf: text, at: position)
      } else {
        signal()
      }
      return Nil
    }
    bindLocked("delete-region", with: bufferMutex) {
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
      return Nil
    }
  }

  private func initializeRegexBuiltins() {
    bindLocked("re-search-forward", with: searchResultsMutex) {
      [unowned self] args in
      guard args.count >= 1,
            let pattern: String = extract(args[0]) else {
        signal()
        return Nil
      }
      searchResults = bufferMutex.locked {
        reSearchForward(pattern: pattern,
                        in: currentBuffer.contents,
                        from: currentBuffer.position)
      }
      if searchResults.isEmpty {
        return Nil
      } else {
        return intern("t")
      }
    }
    bindLocked("match-string", with: searchResultsMutex) {
      [unowned self] args in
      guard args.count == 1,
            let index: Int = extract(args[0]),
            index < searchResults.count else {
        signal()
        return Nil
      }
      return make(searchResults[index].match)
    }
    bindLocked("match-end", with: searchResultsMutex) {
      [unowned self] args in
      guard args.count == 1,
            let index: Int = extract(args[0]),
            index < searchResults.count else {
        signal()
        return Nil
      }
      return bufferMutex.locked {
        make(
          currentBuffer.contents.distance(
            from: currentBuffer.contents.startIndex,
            to: searchResults[index].range.upperBound
          ))
      }
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
        return Nil
      }
    }
    bind("fset") {
      [unowned self] args in
      if args.count == 2, let ref: Reference = extract(args[0]) {
        ref.to = args[1]
      } else {
        signal()
      }
      return Nil
    }
    bind("define-error") {
      [unowned self] _ in
      Nil
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
        return Nil
      }
      let pipe = Pipe()

      let group = filterGroup

      filterQueue.async {
        [unowned self] in
        let readingEnd = pipe.fileHandleForReading
        group.enter()
        while true {
          let availableData = readingEnd.availableData
          if !availableData.isEmpty {
            // Convert Data to String
            if let message = String(data: availableData, encoding: .utf8) {
              filterMutex.locked {
                _ = filter.function([Nil, make(message)])
              }
            }
          } else {
            // No more data, break the loop
            break
          }
          // Sleep to yield time to other tasks and avoid tight looping
          usleep(1000)
        }
        group.leave()
      }

      return make(pipe.fileHandleForWriting.fileDescriptor)
    }
  }
}
