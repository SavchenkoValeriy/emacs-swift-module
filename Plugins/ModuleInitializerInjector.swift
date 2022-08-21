import Foundation

@main
public struct ModuleInitializerInjector {
  static func main() async throws {
    guard CommandLine.argc == 2 else {
      print("Injector takes one argument")
      return
    }

    let initializerSourcePath = URL(fileURLWithPath: CommandLine.arguments[1])
    let initializerSource = """
      import EmacsSwiftModule

      @_cdecl("plugin_is_GPL_compatible")
      public func isGPLCompatible() {}

      @_cdecl("emacs_module_init")
      public func Init(_ runtimePtr: RuntimePointer) -> Int32 {
        do {
          let module: Module = createModule()
          if !module.isGPLCompatible {
            print("Emacs dynamic modules have to be distributed under a GPL compatible license!")
            return 1
          }
          let env = Environment(from: runtimePtr)
          try module.Init(env)
          env.invalidate()
        } catch {
          return 1
        }
        return 0
      }
      """
    try initializerSource.write(to: initializerSourcePath, atomically: true, encoding: .utf8)
  }
}
