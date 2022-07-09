typealias Runtime = emacs_runtime
typealias Environment = emacs_env;

@_cdecl("plugin_is_GPL_compatible")
public func isGPLCompatible() -> Int32 {
    return 1;
}

@_cdecl("emacs_module_init")
public func Init(_ runtimePtr: UnsafeMutablePointer<emacs_runtime>) -> Int32 {
    let runtime: Runtime = runtimePtr.pointee
    let envPtr: UnsafeMutablePointer<emacs_env> = runtime.get_environment(runtimePtr)!
    let env: Environment = envPtr.pointee
    let message: emacs_value = env.intern(envPtr, "message")!

    let hi = "Hello, cruel world!"
    var str: emacs_value? = env.make_string(envPtr, hi, hi.count)
    let _ = env.funcall(envPtr, message, 1, &str)
    return 0
}
