import PackagePlugin

@main
struct ModuleFactoryPlugin: BuildToolPlugin {
  func createBuildCommands(context: PluginContext, target _: Target) async throws
    -> [Command] {
    let outputPath = context.pluginWorkDirectory.appending(
      "ModuleInitializer.swift")
    return try [
      .buildCommand(
        displayName: "Module initialization injection",
        executable: context.tool(named: "ModuleInitializerInjector").path,
        arguments: [outputPath.string],
        outputFiles: [outputPath]
      )
    ]
  }
}
