extension DefunImplementation {
  convenience init<R: EmacsConvertible>(_ original: @escaping () throws -> R) {
    self.init(
      { (env, args) in
        try original().convert(within: env)
      }, 0)
  }
  convenience init<R: EmacsConvertible>(
    _ original: @escaping (Environment) throws -> R
  ) {
    self.init(
      { (env, args) in
        try original(env).convert(within: env)
      }, 0)
  }
  convenience init(_ original: @escaping () throws -> Void) {
    self.init(
      { (env, args) in
        try original()
        return env.Nil
      }, 0)
  }
  convenience init(
    _ original: @escaping (Environment) throws -> Void
  ) {
    self.init(
      { (env, args) in
        try original(env)
        return env.Nil
      }, 0)
  }

  convenience init<T: EmacsConvertible, R: EmacsConvertible>(
    _ original: @escaping (T) throws -> R
  ) {
    self.init(
      { (env, args) in
        try original(T.convert(from: args[0], within: env)).convert(within: env)
      }, 1)
  }
  convenience init<T: EmacsConvertible, R: EmacsConvertible>(
    _ original: @escaping (Environment, T) throws -> R
  ) {
    self.init(
      { (env, args) in
        try original(env, T.convert(from: args[0], within: env)).convert(
          within: env)
      }, 1)
  }
  convenience init<T: EmacsConvertible>(
    _ original: @escaping (T) throws -> Void
  ) {
    self.init(
      { (env, args) in
        try original(T.convert(from: args[0], within: env))
        return env.Nil
      }, 1)
  }
  convenience init<T: EmacsConvertible>(
    _ original: @escaping (Environment, T) throws -> Void
  ) {
    self.init(
      { (env, args) in
        try original(env, T.convert(from: args[0], within: env))
        return env.Nil
      }, 1)
  }

  convenience init<
    T1: EmacsConvertible, T2: EmacsConvertible, R: EmacsConvertible
  >(
    _ original: @escaping (T1, T2) throws -> R
  ) {
    self.init(
      { (env, args) in
        try original(
          T1.convert(from: args[0], within: env),
          T2.convert(from: args[1], within: env)
        ).convert(within: env)
      }, 2)
  }
  convenience init<
    T1: EmacsConvertible, T2: EmacsConvertible, R: EmacsConvertible
  >(
    _ original: @escaping (Environment, T1, T2) throws -> R
  ) {
    self.init(
      { (env, args) in
        try original(
          env, T1.convert(from: args[0], within: env),
          T2.convert(from: args[1], within: env)
        ).convert(within: env)
      }, 2)
  }
  convenience init<T1: EmacsConvertible, T2: EmacsConvertible>(
    _ original: @escaping (T1, T2) throws -> Void
  ) {
    self.init(
      { (env, args) in
        try original(
          T1.convert(from: args[0], within: env),
          T2.convert(from: args[1], within: env)
        )
        return env.Nil
      }, 2)
  }
  convenience init<T1: EmacsConvertible, T2: EmacsConvertible>(
    _ original: @escaping (Environment, T1, T2) throws -> Void
  ) {
    self.init(
      { (env, args) in
        try original(
          env, T1.convert(from: args[0], within: env),
          T2.convert(from: args[1], within: env)
        )
        return env.Nil
      }, 2)
  }

  convenience init<
    T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible,
    R: EmacsConvertible
  >(_ original: @escaping (T1, T2, T3) throws -> R) {
    self.init(
      { (env, args) in
        try original(
          T1.convert(from: args[0], within: env),
          T2.convert(from: args[1], within: env),
          T3.convert(from: args[2], within: env)
        ).convert(within: env)
      }, 3)
  }
  convenience init<
    T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible,
    R: EmacsConvertible
  >(_ original: @escaping (Environment, T1, T2, T3) throws -> R) {
    self.init(
      { (env, args) in
        try original(
          env, T1.convert(from: args[0], within: env),
          T2.convert(from: args[1], within: env),
          T3.convert(from: args[2], within: env)
        ).convert(within: env)
      }, 3)
  }
  convenience init<
    T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible
  >(_ original: @escaping (T1, T2, T3) throws -> Void) {
    self.init(
      { (env, args) in
        try original(
          T1.convert(from: args[0], within: env),
          T2.convert(from: args[1], within: env),
          T3.convert(from: args[2], within: env)
        )
        return env.Nil
      }, 3)
  }
  convenience init<
    T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible
  >(_ original: @escaping (Environment, T1, T2, T3) throws -> Void) {
    self.init(
      { (env, args) in
        try original(
          env, T1.convert(from: args[0], within: env),
          T2.convert(from: args[1], within: env),
          T3.convert(from: args[2], within: env)
        )
        return env.Nil
      }, 3)
  }

  convenience init<
    T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible,
    T4: EmacsConvertible, R: EmacsConvertible
  >(_ original: @escaping (T1, T2, T3, T4) throws -> R) {
    self.init(
      { (env, args) in
        try original(
          T1.convert(from: args[0], within: env),
          T2.convert(from: args[1], within: env),
          T3.convert(from: args[2], within: env),
          T4.convert(from: args[3], within: env)
        ).convert(within: env)
      }, 4)
  }
  convenience init<
    T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible,
    T4: EmacsConvertible, R: EmacsConvertible
  >(_ original: @escaping (Environment, T1, T2, T3, T4) throws -> R) {
    self.init(
      { (env, args) in
        try original(
          env, T1.convert(from: args[0], within: env),
          T2.convert(from: args[1], within: env),
          T3.convert(from: args[2], within: env),
          T4.convert(from: args[3], within: env)
        ).convert(within: env)
      }, 4)
  }
  convenience init<
    T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible,
    T4: EmacsConvertible
  >(_ original: @escaping (T1, T2, T3, T4) throws -> Void) {
    self.init(
      { (env, args) in
        try original(
          T1.convert(from: args[0], within: env),
          T2.convert(from: args[1], within: env),
          T3.convert(from: args[2], within: env),
          T4.convert(from: args[3], within: env)
        )
        return env.Nil
      }, 4)
  }
  convenience init<
    T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible,
    T4: EmacsConvertible
  >(_ original: @escaping (Environment, T1, T2, T3, T4) throws -> Void) {
    self.init(
      { (env, args) in
        try original(
          env, T1.convert(from: args[0], within: env),
          T2.convert(from: args[1], within: env),
          T3.convert(from: args[2], within: env),
          T4.convert(from: args[3], within: env)
        )
        return env.Nil
      }, 4)
  }

  convenience init<
    T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible,
    T4: EmacsConvertible, T5: EmacsConvertible, R: EmacsConvertible
  >(_ original: @escaping (T1, T2, T3, T4, T5) throws -> R) {
    self.init(
      { (env, args) in
        try original(
          T1.convert(from: args[0], within: env),
          T2.convert(from: args[1], within: env),
          T3.convert(from: args[2], within: env),
          T4.convert(from: args[3], within: env),
          T5.convert(from: args[4], within: env)
        ).convert(within: env)
      }, 5)
  }
  convenience init<
    T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible,
    T4: EmacsConvertible, T5: EmacsConvertible, R: EmacsConvertible
  >(_ original: @escaping (Environment, T1, T2, T3, T4, T5) throws -> R) {
    self.init(
      { (env, args) in
        try original(
          env, T1.convert(from: args[0], within: env),
          T2.convert(from: args[1], within: env),
          T3.convert(from: args[2], within: env),
          T4.convert(from: args[3], within: env),
          T5.convert(from: args[4], within: env)
        ).convert(within: env)
      }, 5)
  }
  convenience init<
    T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible,
    T4: EmacsConvertible, T5: EmacsConvertible
  >(_ original: @escaping (T1, T2, T3, T4, T5) throws -> Void) {
    self.init(
      { (env, args) in
        try original(
          T1.convert(from: args[0], within: env),
          T2.convert(from: args[1], within: env),
          T3.convert(from: args[2], within: env),
          T4.convert(from: args[3], within: env),
          T5.convert(from: args[4], within: env)
        )
        return env.Nil
      }, 5)
  }
  convenience init<
    T1: EmacsConvertible, T2: EmacsConvertible, T3: EmacsConvertible,
    T4: EmacsConvertible, T5: EmacsConvertible
  >(_ original: @escaping (Environment, T1, T2, T3, T4, T5) throws -> Void) {
    self.init(
      { (env, args) in
        try original(
          env, T1.convert(from: args[0], within: env),
          T2.convert(from: args[1], within: env),
          T3.convert(from: args[2], within: env),
          T4.convert(from: args[3], within: env),
          T5.convert(from: args[4], within: env)
        )
        return env.Nil
      }, 5)
  }
}

extension Environment {
  public func defun<
    R: EmacsConvertible
  >(
    named name: String,
    with docstring: String = "",
    function: @escaping () throws -> R
  ) throws {
    let wrapped = DefunImplementation(function)
    try defun(named: name, with: docstring, function: wrapped)
  }
  public func defun<
    R: EmacsConvertible
  >(
    named name: String,
    with docstring: String = "",
    function: @escaping (Environment) throws -> R
  ) throws {
    let wrapped = DefunImplementation(function)
    try defun(named: name, with: docstring, function: wrapped)
  }
  public func defun(
    named name: String,
    with docstring: String = "",
    function: @escaping () throws -> Void
  ) throws {
    let wrapped = DefunImplementation(function)
    try defun(named: name, with: docstring, function: wrapped)
  }
  public func defun(
    named name: String,
    with docstring: String = "",
    function: @escaping (Environment) throws -> Void
  ) throws {
    let wrapped = DefunImplementation(function)
    try defun(named: name, with: docstring, function: wrapped)
  }

  public func defun<
    T: EmacsConvertible,
    R: EmacsConvertible
  >(
    named name: String,
    with docstring: String = "",
    function: @escaping (T) throws -> R
  ) throws {
    let wrapped = DefunImplementation(function)
    try defun(named: name, with: docstring, function: wrapped)
  }
  public func defun<
    T: EmacsConvertible,
    R: EmacsConvertible
  >(
    named name: String,
    with docstring: String = "",
    function: @escaping (Environment, T) throws -> R
  ) throws {
    let wrapped = DefunImplementation(function)
    try defun(named: name, with: docstring, function: wrapped)
  }
  public func defun<
    T: EmacsConvertible
  >(
    named name: String,
    with docstring: String = "",
    function: @escaping (T) throws -> Void
  ) throws {
    let wrapped = DefunImplementation(function)
    try defun(named: name, with: docstring, function: wrapped)
  }
  public func defun<
    T: EmacsConvertible
  >(
    named name: String,
    with docstring: String = "",
    function: @escaping (Environment, T) throws -> Void
  ) throws {
    let wrapped = DefunImplementation(function)
    try defun(named: name, with: docstring, function: wrapped)
  }

  public func defun<
    T1: EmacsConvertible,
    T2: EmacsConvertible,
    R: EmacsConvertible
  >(
    named name: String,
    with docstring: String = "",
    function: @escaping (T1, T2) throws -> R
  ) throws {
    let wrapped = DefunImplementation(function)
    try defun(named: name, with: docstring, function: wrapped)
  }
  public func defun<
    T1: EmacsConvertible,
    T2: EmacsConvertible,
    R: EmacsConvertible
  >(
    named name: String,
    with docstring: String = "",
    function: @escaping (Environment, T1, T2) throws -> R
  ) throws {
    let wrapped = DefunImplementation(function)
    try defun(named: name, with: docstring, function: wrapped)
  }
  public func defun<
    T1: EmacsConvertible,
    T2: EmacsConvertible
  >(
    named name: String,
    with docstring: String = "",
    function: @escaping (T1, T2) throws -> Void
  ) throws {
    let wrapped = DefunImplementation(function)
    try defun(named: name, with: docstring, function: wrapped)
  }
  public func defun<
    T1: EmacsConvertible,
    T2: EmacsConvertible
  >(
    named name: String,
    with docstring: String = "",
    function: @escaping (Environment, T1, T2) throws -> Void
  ) throws {
    let wrapped = DefunImplementation(function)
    try defun(named: name, with: docstring, function: wrapped)
  }

  public func defun<
    T1: EmacsConvertible,
    T2: EmacsConvertible,
    T3: EmacsConvertible,
    R: EmacsConvertible
  >(
    named name: String,
    with docstring: String = "",
    function: @escaping (T1, T2, T3) throws -> R
  ) throws {
    let wrapped = DefunImplementation(function)
    try defun(named: name, with: docstring, function: wrapped)
  }
  public func defun<
    T1: EmacsConvertible,
    T2: EmacsConvertible,
    T3: EmacsConvertible,
    R: EmacsConvertible
  >(
    named name: String,
    with docstring: String = "",
    function: @escaping (Environment, T1, T2, T3) throws -> R
  ) throws {
    let wrapped = DefunImplementation(function)
    try defun(named: name, with: docstring, function: wrapped)
  }
  public func defun<
    T1: EmacsConvertible,
    T2: EmacsConvertible,
    T3: EmacsConvertible
  >(
    named name: String,
    with docstring: String = "",
    function: @escaping (T1, T2, T3) throws -> Void
  ) throws {
    let wrapped = DefunImplementation(function)
    try defun(named: name, with: docstring, function: wrapped)
  }
  public func defun<
    T1: EmacsConvertible,
    T2: EmacsConvertible,
    T3: EmacsConvertible
  >(
    named name: String,
    with docstring: String = "",
    function: @escaping (Environment, T1, T2, T3) throws -> Void
  ) throws {
    let wrapped = DefunImplementation(function)
    try defun(named: name, with: docstring, function: wrapped)
  }

  public func defun<
    T1: EmacsConvertible,
    T2: EmacsConvertible,
    T3: EmacsConvertible,
    T4: EmacsConvertible,
    R: EmacsConvertible
  >(
    named name: String,
    with docstring: String = "",
    function: @escaping (T1, T2, T3, T4) throws -> R
  ) throws {
    let wrapped = DefunImplementation(function)
    try defun(named: name, with: docstring, function: wrapped)
  }
  public func defun<
    T1: EmacsConvertible,
    T2: EmacsConvertible,
    T3: EmacsConvertible,
    T4: EmacsConvertible,
    R: EmacsConvertible
  >(
    named name: String,
    with docstring: String = "",
    function: @escaping (Environment, T1, T2, T3, T4) throws -> R
  ) throws {
    let wrapped = DefunImplementation(function)
    try defun(named: name, with: docstring, function: wrapped)
  }
  public func defun<
    T1: EmacsConvertible,
    T2: EmacsConvertible,
    T3: EmacsConvertible,
    T4: EmacsConvertible
  >(
    named name: String,
    with docstring: String = "",
    function: @escaping (T1, T2, T3, T4) throws -> Void
  ) throws {
    let wrapped = DefunImplementation(function)
    try defun(named: name, with: docstring, function: wrapped)
  }
  public func defun<
    T1: EmacsConvertible,
    T2: EmacsConvertible,
    T3: EmacsConvertible,
    T4: EmacsConvertible
  >(
    named name: String,
    with docstring: String = "",
    function: @escaping (Environment, T1, T2, T3, T4) throws -> Void
  ) throws {
    let wrapped = DefunImplementation(function)
    try defun(named: name, with: docstring, function: wrapped)
  }

  public func defun<
    T1: EmacsConvertible,
    T2: EmacsConvertible,
    T3: EmacsConvertible,
    T4: EmacsConvertible,
    T5: EmacsConvertible,
    R: EmacsConvertible
  >(
    named name: String,
    with docstring: String = "",
    function: @escaping (T1, T2, T3, T4, T5) throws -> R
  ) throws {
    let wrapped = DefunImplementation(function)
    try defun(named: name, with: docstring, function: wrapped)
  }
  public func defun<
    T1: EmacsConvertible,
    T2: EmacsConvertible,
    T3: EmacsConvertible,
    T4: EmacsConvertible,
    T5: EmacsConvertible,
    R: EmacsConvertible
  >(
    named name: String,
    with docstring: String = "",
    function: @escaping (Environment, T1, T2, T3, T4, T5) throws -> R
  ) throws {
    let wrapped = DefunImplementation(function)
    try defun(named: name, with: docstring, function: wrapped)
  }
  public func defun<
    T1: EmacsConvertible,
    T2: EmacsConvertible,
    T3: EmacsConvertible,
    T4: EmacsConvertible,
    T5: EmacsConvertible
  >(
    named name: String,
    with docstring: String = "",
    function: @escaping (T1, T2, T3, T4, T5) throws -> Void
  ) throws {
    let wrapped = DefunImplementation(function)
    try defun(named: name, with: docstring, function: wrapped)
  }
  public func defun<
    T1: EmacsConvertible,
    T2: EmacsConvertible,
    T3: EmacsConvertible,
    T4: EmacsConvertible,
    T5: EmacsConvertible
  >(
    named name: String,
    with docstring: String = "",
    function: @escaping (Environment, T1, T2, T3, T4, T5) throws -> Void
  ) throws {
    let wrapped = DefunImplementation(function)
    try defun(named: name, with: docstring, function: wrapped)
  }
}
