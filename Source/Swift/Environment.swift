import EmacsModule

class Environment {
    internal let raw: UnsafeMutablePointer<emacs_env>

    public init(from: UnsafeMutablePointer<emacs_env>) {
        raw = from
    }

    public init(from: UnsafeMutablePointer<emacs_runtime>) {
        raw = from.pointee.get_environment(from)!
    }

    public func intern(_ name: String) -> EmacsValue {
        return EmacsValue(from: raw.pointee.intern(raw, name))
    }
}
