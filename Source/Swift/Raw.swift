import EmacsModule

typealias RawEmacsValue = emacs_value
typealias RawEnvironment = UnsafeMutablePointer<emacs_env>?
typealias RawValuePointer = UnsafeMutablePointer<RawEmacsValue?>?
typealias RawFunctionType = @convention(c) (
  RawEnvironment, Int, RawValuePointer, UnsafeMutableRawPointer?
) -> RawEmacsValue?
