//
// Lock.swift
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
import Foundation

#if os(macOS)
  import os.lock
#endif

final class Lock {
  // See http://www.russbishop.net/the-law for explanation why
  // it has to be done this way.
  #if os(macOS)
    typealias Impl = os_unfair_lock_s
    private func makeLock() -> Impl { os_unfair_lock() }
    private func lock() { os_unfair_lock_lock(impl) }
    private func unlock() { os_unfair_lock_unlock(impl) }
  #else
    typealias Impl = NSLock
    private func makeLock() -> Impl { NSLock() }
    private func lock() { impl.pointee.lock() }
    private func unlock() { impl.pointee.unlock() }
  #endif

  private var impl: UnsafeMutablePointer<Impl>

  init() {
    impl = UnsafeMutablePointer<Impl>.allocate(capacity: 1)
    impl.initialize(to: makeLock())
  }

  deinit {
    impl.deallocate()
  }

  func locked<R>(_ body: () throws -> R) rethrows -> R {
    lock()
    defer { unlock() }
    return try body()
  }
}
