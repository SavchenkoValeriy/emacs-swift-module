import EmacsModule

public typealias RuntimePointer = UnsafeMutablePointer<emacs_runtime>

typealias RawEmacsValue = emacs_value
typealias RawEnvironment = UnsafeMutablePointer<emacs_env>?
typealias RawOpaquePointer = UnsafeMutableRawPointer
typealias RawValuePointer = UnsafeMutablePointer<RawEmacsValue?>?
typealias RawFunctionType = @convention(c) (
  RawEnvironment, Int, RawValuePointer, UnsafeMutableRawPointer?
) -> RawEmacsValue?
typealias RawFinalizer = @convention(c) (RawOpaquePointer?) -> Void
