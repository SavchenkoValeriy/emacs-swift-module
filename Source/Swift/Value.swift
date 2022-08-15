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
    for freedValue in freedPersistentValues {
      try? release(EmacsValue(from: freedValue))
    }
    freedPersistentValues.removeAll()
  }
}
