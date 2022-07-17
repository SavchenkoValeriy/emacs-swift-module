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
    try env.defun(named: "swift-int") { (arg: Int) in arg * 2 }
    try env.defun(named: "swift-float") { (arg: Double) in arg * 2 }
    try env.defun(named: "swift-bool") { (arg: Bool) in !arg }
    try env.defun(named: "swift-call") {
      (env: Environment, arg: String) throws in
      return try env.funcall("format", with: "'%s'", arg)
    }
    try env.defun(named: "swift-calls-bad-function") {
      (env: Environment) throws in try env.funcall("iwuvjdnc", with: 42)
    }
    try env.defun(named: "swift-throws", with: "") { (x: Int) throws -> Int in
      throw MyError(x: x)
    }
    try env.defun(named: "swift-throws-sometimes") { (x: Int) -> Int in
      if x == 42 {
        throw EmacsError.customError(message: "Got 42!")
      }
      return x
    }
    try env.defun(named: "swift-create-a") { return MyClassA() }
    try env.defun(named: "swift-create-b") { return MyClassB() }
    try env.defun(named: "swift-get-a-x") { (a: MyClassA) in a.x }
    try env.defun(named: "swift-get-a-y") { (a: MyClassA) in a.y }
    try env.defun(named: "swift-get-b-z") { (b: MyClassB) in b.z }
    try env.defun(named: "swift-set-a-x") { (a: MyClassA, x: Int) in a.x = x
    }
    try env.defun(named: "swift-set-a-y") { (a: MyClassA, y: String) in a.y = y
    }
    try env.defun(named: "swift-set-b-z") { (b: MyClassB, z: Double) in b.z = z
    }
    try env.defun(named: "swift-sum-array") { (a: [Int]) in a.reduce(0, +) }
    try env.defun(named: "swift-map-array") {
      (env: Environment, a: [Int], fun: EmacsValue) throws -> [EmacsValue] in
      try a.map { try env.funcall(fun, with: $0) }
    }
  } catch {
    return 1
  }
  return 0
}
