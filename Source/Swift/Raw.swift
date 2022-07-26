import EmacsModule

/// A raw C pointer type from Emacs for the runtime.
public typealias RuntimePointer = UnsafeMutablePointer<emacs_runtime>

typealias RawEmacsValue = emacs_value?
typealias RawEnvironment = UnsafeMutablePointer<emacs_env>?
typealias RawOpaquePointer = UnsafeMutableRawPointer
typealias RawValuePointer = UnsafeMutablePointer<RawEmacsValue>?
typealias RawFunctionType = @convention(c) (
  RawEnvironment, Int, RawValuePointer, UnsafeMutableRawPointer?
) -> RawEmacsValue
typealias RawFinalizer = @convention(c) (RawOpaquePointer?) -> Void
