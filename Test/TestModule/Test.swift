import EmacsSwiftModule

@_cdecl("plugin_is_GPL_compatible")
public func isGPLCompatible() {}

struct MyError: Error {
  let x: Int
}

@_cdecl("emacs_module_init")
public func Init(_ runtimePtr: RuntimePointer) -> Int32 {
  let env = Environment(from: runtimePtr)
  do {
    try env.defn(named: "swift-int") { (arg: Int) in arg * 2 }
    try env.defn(named: "swift-float") { (arg: Double) in arg * 2 }
    try env.defn(named: "swift-bool") { (arg: Bool) in !arg }
    try env.defn(named: "swift-call") { (env: Environment, arg: String) throws in
      return try env.funcall("format", with: "'%s'", arg)
    }
    try env.defn(named: "swift-calls-bad-function") {
      (env: Environment) throws in try env.funcall("iwuvjdnc", with: 42)
    }
    try env.defn(named: "swift-throws", with: "") { (x: Int) throws -> Int in
      throw MyError(x: x)
    }
    try env.defn(named: "swift-throws-sometimes") { (x: Int) -> Int in
      if x == 42 {
        throw EmacsError.customError(message: "Got 42!")
      }
      return x
    }
  } catch {
    return 1
  }
  return 0
}
