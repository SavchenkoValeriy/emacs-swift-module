import PackagePlugin

@main
struct ModuleFactoryPlugin: BuildToolPlugin {
  func createBuildCommands(context: PluginContext, target: Target) async throws
    -> [Command]
  {
    let outputPath = context.pluginWorkDirectory.appending(
      "ModuleInitializer.swift")
    return [
      .buildCommand(
        displayName: "Module initialization injection",
        executable: try context.tool(named: "ModuleInitializerInjector").path,
        arguments: [outputPath.string],
        outputFiles: [outputPath]
      )
    ]
  }
}
