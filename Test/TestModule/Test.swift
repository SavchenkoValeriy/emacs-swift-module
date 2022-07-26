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

func someAsyncTask(completion: () -> Void) async throws {
  try await Task.sleep(nanoseconds: 50_000_000)
  completion()
}

func someAsyncTaskWithResult(completion: (Int) -> Void) async throws {
  try await Task.sleep(nanoseconds: 50_000_000)
  completion(42)
}

@_cdecl("emacs_module_init")
public func Init(_ runtimePtr: RuntimePointer) -> Int32 {
  let env = Environment(from: runtimePtr)
  do {
    try env.defun("swift-int") { (arg: Int) in arg * 2 }
    try env.defun("swift-float") { (arg: Double) in arg * 2 }
    try env.defun("swift-bool") { (arg: Bool) in !arg }
    try env.defun("swift-call") {
      (env: Environment, arg: String) throws in
      return try env.funcall("format", with: "'%s'", arg)
    }
    try env.defun("swift-calls-bad-function") {
      (env: Environment) throws in try env.funcall("iwuvjdnc", with: 42)
    }
    try env.defun("swift-throws", with: "") { (x: Int) throws -> Int in
      throw MyError(x: x)
    }
    try env.defun("swift-throws-sometimes") { (x: Int) -> Int in
      if x == 42 {
        throw EmacsError.customError(message: "Got 42!")
      }
      return x
    }
    try env.defun("swift-create-a") { return MyClassA() }
    try env.defun("swift-create-b") { return MyClassB() }
    try env.defun("swift-get-a-x") { (a: MyClassA) in a.x }
    try env.defun("swift-get-a-y") { (a: MyClassA) in a.y }
    try env.defun("swift-get-b-z") { (b: MyClassB) in b.z }
    try env.defun("swift-set-a-x") { (a: MyClassA, x: Int) in a.x = x
    }
    try env.defun("swift-set-a-y") { (a: MyClassA, y: String) in a.y = y
    }
    try env.defun("swift-set-b-z") { (b: MyClassB, z: Double) in b.z = z
    }
    try env.defun("swift-sum-array") { (a: [Int]) in a.reduce(0, +) }
    try env.defun("swift-map-array") {
      (env: Environment, a: [Int], fun: EmacsValue) throws -> [EmacsValue] in
      try a.map { try env.funcall(fun, with: $0) }
    }
    try env.defun("swift-optional-arg") { (a: Int?) in return a ?? 42 }
    try env.defun("swift-optional-result") { (a: Int) -> Int? in
      return a == 42 ? nil : a * 2
    }
    let captured = MyClassA()
    try env.defun("swift-get-captured-a-x", function: { captured.x })
    try env.defun(
      "swift-set-captured-a-x", function: { (x: Int) in captured.x = x })
    try env.defun("swift-typed-funcall") {
      (env: Environment, x: EmacsValue) throws -> String in
      try env.funcall("format", with: "%S", x)
    }
    try env.defun("swift-incorrect-typed-funcall") {
      (env: Environment, x: EmacsValue) throws -> Int in
      try env.funcall("format", with: "%S", x)
    }
    try env.defun("swift-symbol-name") { (x: Symbol) in
      x.name
    }
    let lambda = try env.preserve(env.defun { (x: String) in "Received \(x)" })
    try env.defun("swift-call-lambda") { (env: Environment, arg: String) in
      try env.funcall(lambda, with: arg)
    }
    try env.defun("swift-get-lambda") { lambda }
    let channel = try env.openChannel(name: "test")
    try env.defun("swift-async-channel") {
      (callback: PersistentEmacsValue) in
      Task {
        try await someAsyncTask(
          completion: channel.callback {
            (env: Environment) throws in try env.funcall(callback)
          })
      }
    }
    try env.defun("swift-async-lisp-callback") {
      (callback: PersistentEmacsValue) in
      Task {
        try await someAsyncTask(completion: channel.callback(callback))
      }
    }
    try env.defun("swift-async-normal-hook") {
      Task {
        try await someAsyncTask(completion: channel.hook("normal-hook"))
      }
    }
    try env.defun("swift-async-abnormal-hook") {
      Task {
        try await someAsyncTaskWithResult(
          completion: channel.hook("abnormal-hook"))
      }
    }
    var persistentArray = [EmacsValue]()
    try env.defun("swift-add-to-array") {
      (x: PersistentEmacsValue) in persistentArray.append(x)
    }
    try env.defun("swift-get-array") { persistentArray }
  } catch {
    return 1
  }
  return 0
}
