@_cdecl("plugin_is_GPL_compatible")
public func isGPLCompatible() -> Int32 {
    return 1
}

typealias RawEmacsValue = emacs_value
typealias RawEnvironment = UnsafeMutablePointer<emacs_env>?
typealias RawValuePointer = UnsafeMutablePointer<RawEmacsValue?>?
typealias RawFunctionType = @convention(c) (RawEnvironment, Int, RawValuePointer, UnsafeMutableRawPointer?) -> RawEmacsValue?

struct EmacsValue {
    let raw: emacs_value?
    public init(from: emacs_value?) {
        raw = from
    }
}

protocol EmacsConvertible {
    func convert(within env: Environment) -> EmacsValue
    static func convert(from: EmacsValue, within env: Environment) -> Self
}

extension String: EmacsConvertible {
    func convert(within env: Environment) -> EmacsValue {
        return env.make(self)
    }

    static func convert(from: EmacsValue, within env: Environment) -> String {
        return env.toString(from)
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

    //
    // FUNCALL variants
    //
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

    //
    // Value factories
    //
    public func make(_ from: String) -> EmacsValue {
        return EmacsValue(from: raw.pointee.make_string(raw, from, from.count))
    }

    //
    // Converter functions
    //
    public func toString(_ value: EmacsValue) -> String {
        var len = 0
        let _ = raw.pointee.copy_string_contents(raw, value.raw, nil, &len)
        var buf = [CChar](repeating: 0, count: len)
        let _ = raw.pointee.copy_string_contents(raw, value.raw, &buf, &len)
        return String(cString: buf)
    }

    //
    // Make function
    //
    class Wrapper {
        let function: (Environment, [EmacsValue]) -> EmacsValue
        init<T: EmacsConvertible, R: EmacsConvertible>(_ original: @escaping (T) -> R) {
            function = { (env, args) in
                original(T.convert(from: args[0], within: env)).convert(within: env)
            }
        }
    }

    public func defn<T: EmacsConvertible,
                     R: EmacsConvertible>(named name: String,
                                          with docstring: String = "",
                                          function: @escaping (T) -> R) {
        let wrapped = Wrapper(function)
        let actualFunction: RawFunctionType = { rawEnv, num, args, data in
            let env = Environment(from: rawEnv!)
            let arg = EmacsValue(from: args?.pointee)
            let impl = Unmanaged<Wrapper>.fromOpaque(data!).takeUnretainedValue()
            let result = impl.function(env, [arg])
            return result.raw
        }
        let wrappedPtr = Unmanaged.passRetained(wrapped).toOpaque()
        let funcValue = EmacsValue(from: raw.pointee.make_function(raw, 1, 1, actualFunction, docstring, wrappedPtr))
        let symbol = intern(name)
        let _ = funcall("fset", with: symbol, funcValue)
    }
}

@_cdecl("emacs_module_init")
public func Init(_ runtimePtr: UnsafeMutablePointer<emacs_runtime>) -> Int32 {
    let env = Environment(from: runtimePtr)
    env.defn(named: "swift-test", with: "") { (arg: String) in "I received \(arg)!!" }
    return 0
}
