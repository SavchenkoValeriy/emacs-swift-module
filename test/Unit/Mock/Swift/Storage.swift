//
// Storage.swift
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

// Stored value allows us to expose pointers to boxes as emacs_values.
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

// Opaque box wrapping some stored value and its finalizer.
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

// A value that simply refers to a different value.
class Reference {
  var to: emacs_value

  init(_ to: emacs_value) {
    self.to = to
  }
}

// Raw untyped function.
typealias Function = ([emacs_value]) -> emacs_value

// FunctionData stores all function-related data similar to how Emacs handles it.
struct FunctionData {
  let function: Function
  let payload: RawOpaquePointer?
}
