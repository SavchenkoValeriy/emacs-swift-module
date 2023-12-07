//
// Variadic+Utils.swift
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
#if swift(>=5.9)
  internal func counter() -> () -> Int {
    var count = 0
    return {
      defer { count += 1 }
      return count
    }
  }
  internal func count<each T>(_ types: repeat (each T).Type) -> Int {
    let index = counter()
    _ = (repeat (each types, index()))
    return index()
  }

  internal func withTupleAsArray<each T: EmacsConvertible>(
    _ element: repeat each T, function: ([EmacsConvertible]) throws -> Void
  ) rethrows {
    let tuple = (repeat (each element) as EmacsConvertible)
    return try withUnsafePointer(to: tuple) { tuplePtr in
      let start = UnsafeRawPointer(tuplePtr).assumingMemoryBound(
        to: EmacsConvertible.self)
      let buf = UnsafeBufferPointer(
        start: start, count: count(repeat (each T).self))
      try function([EmacsConvertible](buf))
    }
  }
#endif
