import EmacsSwiftModule
import Foundation

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

class TestModule: Module {
  let isGPLCompatible = true

  func Init(_ env: Environment) throws {
    try env.defun("swift-int") { (arg: Int) in arg * 2 }
    try env.defun("swift-float") { (arg: Double) in arg * 2 }
    try env.defun("swift-bool") { (arg: Bool) in !arg }
    try env.defun("swift-string") { (arg: String) in arg }
    try env.defun("swift-data") { (arg: Data) in arg }
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

    try env.defun("swift-cons-arg") {
      (arg: ConsCell<Int, String>) in
      "(\(arg.car) . \(arg.cdr))"
    }
    try env.defun("swift-cons-return") {
      (arg: [Int]) in
      arg.map { x in ConsCell(car: x, cdr: x * x) }
    }
    try env.defun("swift-list") {
      (arg: List<Int>) in
      List(from: arg.map { $0 * 2 })
    }
    try env.defun("swift-list-length") {
      (arg: List<EmacsValue>) in arg.reduce(0) { (x, _) in x + 1 }
    }
    try env.defun("swift-alist") {
      (arg: [Int: String]) in
      arg.filter { $0.key == 42 }
    }
    try env.defun("swift-env-misuse-lifetime") {
      try env.funcall("message", with: "Some message")
    }
    try env.defun("swift-env-misuse-thread") {
      (env: Environment, callback: PersistentEmacsValue) throws in
      Task.detached {
        try env.funcall(callback)
      }
    }
    try env.defun("swift-result-conversion-error") {
      env in try env.funcall("+", with: 1, 1) as String
    }

    if env.version >= .Emacs28 {
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
      try env.defun("swift-async-channel-with-result") {
        (callback: PersistentEmacsValue) in
        Task {
          try await someAsyncTaskWithResult(
            completion: channel.callback(callback))
        }
      }
      try env.defun("swift-nested-async-with-result") {
        (callback: PersistentEmacsValue) in
        Task {
          try await someAsyncTaskWithResult(
            completion: channel.callback {
              (_, x) in channel.callback(callback)(x)
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
      try env.defun("swift-with-environment") {
        (callback: PersistentEmacsValue) in
        Task {
          channel.withEnvironment {
            (env: Environment) throws in
            try env.funcall(callback)
          }
        }
      }
      try env.defun("swift-with-async-environment") {
        (x: Int, callback: PersistentEmacsValue) in
        Task {
          async let a: Int = channel.withAsyncEnvironment {
            env in try env.funcall("+", with: x, 42)
          }
          async let b: Int = channel.withAsyncEnvironment {
            env in try env.funcall("*", with: x, 2)
          }
          let result = try await a - b
          channel.withEnvironment {
            env in try env.funcall(callback, with: result)
          }
        }
      }
    }
  }
}

func createModule() -> Module { TestModule() }
