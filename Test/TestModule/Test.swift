import EmacsSwiftModule

@_cdecl("plugin_is_GPL_compatible")
public func isGPLCompatible() {}

struct MyError: Error {
  let x: Int
}

class MyClassA: OpaquelyEmacsConvertible {
  public var x: Int = 42
  public var y: String = "Hello"
}

class MyClassB: OpaquelyEmacsConvertible {
  public var z: Double = 36.6
}

@_cdecl("emacs_module_init")
public func Init(_ runtimePtr: RuntimePointer) -> Int32 {
  let env = Environment(from: runtimePtr)
  do {
    try env.defn(named: "swift-int") { (arg: Int) in arg * 2 }
    try env.defn(named: "swift-float") { (arg: Double) in arg * 2 }
    try env.defn(named: "swift-bool") { (arg: Bool) in !arg }
    try env.defn(named: "swift-call") {
      (env: Environment, arg: String) throws in
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
    try env.defn(named: "swift-create-a") { return MyClassA() }
    try env.defn(named: "swift-create-b") { return MyClassB() }
    try env.defn(named: "swift-get-a-x") { (a: MyClassA) in a.x }
    try env.defn(named: "swift-get-a-y") { (a: MyClassA) in a.y }
    try env.defn(named: "swift-get-b-z") { (b: MyClassB) in b.z }
    try env.defn(named: "swift-set-a-x") { (a: MyClassA, x: Int) in a.x = x
    }
    try env.defn(named: "swift-set-a-y") { (a: MyClassA, y: String) in a.y = y }
    try env.defn(named: "swift-set-b-z") { (b: MyClassB, z: Double) in b.z = z }
  } catch {
    return 1
  }
  return 0
}
