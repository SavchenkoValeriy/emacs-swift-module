//
// Value.swift
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

/// An opaque Emacs value representing something from the Emacs Lisp world.
///
/// Please, don't assume anything based on this object and treat it as a
/// black box.
///
/// ``EmacsValue`` is only useful together with ``Environment``.
public class EmacsValue {
  let raw: RawEmacsValue
  required init(from: RawEmacsValue) {
    raw = from
  }
  required init(from: EmacsValue, within env: Environment) throws {
    raw = from.raw
  }
}

private var freedPersistentValues = [RawEmacsValue]()

/// An Emacs value that can be safely copied and stored.
///
/// Unlike a regular ``EmacsValue``, it has a lifetime controlled
/// by the Swift side and is guaranteed to be valid while the object
/// has references to it.
///
/// See <doc:Lifetimes> for additional info.
public final class PersistentEmacsValue: EmacsValue {
  required init(from: RawEmacsValue) {
    super.init(from: from)
  }
  required init(from: EmacsValue, within env: Environment) throws {
    super.init(from: try env.retain(from).raw)
  }
  deinit {
    freedPersistentValues.append(raw)
  }
}

extension Environment {
  func cleanup() {
    guard valid,
          threadValid,
          !inErrorState(),
          !interrupted() else {
      // Can't cleanup when the environment in a bad or inconsistent
      // state.
      return
    }

    for freedValue in freedPersistentValues {
      try? release(EmacsValue(from: freedValue))
    }
    freedPersistentValues.removeAll()
  }
}
