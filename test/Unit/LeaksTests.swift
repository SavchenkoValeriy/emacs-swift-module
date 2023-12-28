//
// LeaksTests.swift
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
import XCTest

// Only build when built through SPM, as tests run through Xcode don't like this.
// Add LEAKS flag once we figure out a way to automate this.
// Can run by invoking swift test -c debug -Xswiftc -DLEAKS.
// Sample code from the Swift forums: https://forums.swift.org/t/test-for-memory-leaks-in-ci/36526/19
#if LEAKS && os(macOS)
  final class LeaksTests: XCTestCase {
    func testForLeaks() {
      // Sets up an atexit handler that invokes the leaks tool.
      atexit {
        @discardableResult
        func leaksTo(_ file: String) -> Process {
          let out = FileHandle(forWritingAtPath: file)!
          defer {
            if #available(macOS 10.15, *) {
              try! out.close()
            } else {
              // Fallback on earlier versions
            }
          }
          let process = Process()
          process.launchPath = "/usr/bin/leaks"
          process.arguments = ["\(getpid())"]
          process.standardOutput = out
          process.standardError = out
          process.launch()
          process.waitUntilExit()
          return process
        }
        let process = leaksTo("/dev/null")
        guard process.terminationReason == .exit, [0, 1].contains(process.terminationStatus) else {
          print("Process terminated: \(process.terminationReason): \(process.terminationStatus)")
          exit(255)
        }
        if process.terminationStatus == 1 {
          print("================")
          print("Leaks Detected!!!")
          leaksTo("/dev/tty")
        }
        exit(process.terminationStatus)
      }
    }
  }
#endif
