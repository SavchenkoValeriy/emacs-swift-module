@_cdecl("plugin_is_GPL_compatible")
public func isGPLCompatible() -> Int32 {
    return 1
}

struct EmacsValue {
    let raw: emacs_value?
    public init(from: emacs_value?) {
        raw = from
    }
}

protocol EmacsConvertible {
    func convert(within env: Environment) -> EmacsValue
}

extension String: EmacsConvertible {
    func convert(within env: Environment) -> EmacsValue {
        return env.make(self)
    }
}

class Environment {
    private let raw: UnsafeMutablePointer<emacs_env>

    public init(from: UnsafeMutablePointer<emacs_env>) {
        raw = from
    }

    public init(from: UnsafeMutablePointer<emacs_runtime>) {
        raw = from.pointee.get_environment(from)!
    }

    public func intern(_ name: String) -> EmacsValue {
        return EmacsValue(from: raw.pointee.intern(raw, name))
    }
    public func funcall(_ fun: EmacsValue, with args: [EmacsValue]) -> EmacsValue {
        var rawArgs = args.map { $0.raw }
        return EmacsValue(from: raw.pointee.funcall(raw, fun.raw, args.count, &rawArgs))
    }
    public func funcall(_ fun: EmacsValue, with args: EmacsValue...) -> EmacsValue {
        return funcall(fun, with: args)
    }
    public func funcall(_ fun: EmacsValue, with args: [EmacsConvertible]) -> EmacsValue {
        return funcall(fun, with: args.map { $0.convert(within: self) })
    }
    public func funcall(_ fun: EmacsValue, with args: EmacsConvertible...) -> EmacsValue {
        return funcall(fun, with: args)
    }
    public func funcall(_ fun: String, with args: [EmacsValue]) -> EmacsValue {
        return funcall(intern(fun), with: args)
    }
    public func funcall(_ fun: String, with args: EmacsValue...) -> EmacsValue {
        return funcall(fun, with: args)
    }
    public func funcall(_ fun: String, with args: [EmacsConvertible]) -> EmacsValue {
        return funcall(fun, with: args.map { $0.convert(within: self) })
    }
    public func funcall(_ fun: String, with args: EmacsConvertible...) -> EmacsValue {
        return funcall(fun, with: args)
    }
    public func make(_ from: String) -> EmacsValue {
        return EmacsValue(from: raw.pointee.make_string(raw, from, from.count))
    }
}

@_cdecl("emacs_module_init")
public func Init(_ runtimePtr: UnsafeMutablePointer<emacs_runtime>) -> Int32 {
    let env = Environment(from: runtimePtr)
    let _ = env.funcall("message", with: "Hello, cruel world!")
    return 0
}
