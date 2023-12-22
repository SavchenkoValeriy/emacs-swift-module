import XCTest

func isExecutableInPath(_ executable: String) -> Bool {
  let path = ProcessInfo.processInfo.environment["PATH"] ?? ""
  let paths = path.components(separatedBy: ":")
  return paths.contains { FileManager.default.fileExists(atPath: $0 + "/" + executable) }
}

func findEmacsMajorVersion() -> Int? {
  // Check if emacs is available in PATH
  if !isExecutableInPath("emacs") {
    print("Couldn't find Emacs")
    return nil
  }

  // Set up Process and Pipe to run emacs --version
  let process = Process()
  let pipe = Pipe()
  process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
  process.arguments = ["emacs", "--version"]
  process.standardOutput = pipe

  do {
    try process.run()
    process.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    if let output = String(data: data, encoding: .utf8) {
      // Parse major version number from the output
      let lines = output.components(separatedBy: "\n")
      if let firstLine = lines.first, let versionString = firstLine.split(separator: " ").last {
        let versionComponents = versionString.split(separator: ".")
        if let majorVersionString = versionComponents.first, let majorVersion = Int(majorVersionString) {
          return majorVersion
        }
      }
    }
  } catch {
    print("Failed to run emacs --version")
  }

  return nil
}

func runCommand(_ args: [String], with env: [String: String] = [:],
                redirect: Bool = true) -> Bool {
  let process = Process()
  let pipe = Pipe()

  process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
  process.arguments = args
  if redirect {
    process.standardOutput = pipe
    process.standardError = pipe
  }

  // Add environment variables
  var environment = ProcessInfo.processInfo.environment // Get current environment
  environment.merge(env) { _, provided in provided }
  process.environment = environment

  do {
    try process.run()
    process.waitUntilExit()
    if process.terminationStatus != 0 {
      if redirect {
        let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: outputData, encoding: .utf8) {
          print(output)
        }
      }
      return false
    }
    return true
  } catch {
    print("Failed to run \(args.joined(separator: " ")) command: \(error)")
    return false
  }
}

func runCaskInstall() -> Bool {
  runCommand(["cask", "install"])
}

func runSwiftBuild(_ buildType: String) -> Bool {
  runCommand(["swift", "build", "-c", buildType])
}

func runCaskLoadPath() -> String? {
  let process = Process()
  let pipe = Pipe()

  process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
  process.arguments = ["cask", "load-path"]
  process.standardOutput = pipe
  process.standardError = pipe

  do {
    try process.run()
    process.waitUntilExit()
    guard process.terminationStatus == 0,
          let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) else {
      return nil
    }

    return output
  } catch {
    print("Failed to run cask install command: \(error)")
    return nil
  }
}

func runTests(_ version: Int, buildType: String, loadPath: String) -> Bool {
  let entry = "(ert-run-tests-batch-and-exit '(or (tag emacs-all) (tag emacs-\(version))))"
  let command = ["emacs", "-Q", "-batch", "-l", "ert",
                 "-l", "./test/swift-module-test.el",
                 "-l", "./.build/\(buildType)/libTestModule.dylib",
                 "-eval", entry]
  print("Command:\nEMACSLOADPATH=`cask load-path` \(command.joined(separator: " "))")
  return runCommand(command, with: ["EMACSLOADPATH": loadPath], redirect: false)
}

func sourceFileDirectory(file: String = #file) -> String {
  let fileURL = URL(fileURLWithPath: file)
  return fileURL.deletingLastPathComponent().path
}

func cd(_ relative: String) {
  FileManager.default.changeCurrentDirectoryPath("\(sourceFileDirectory())/\(relative)")
}

class IntegrationTests: XCTestCase {
  func testModule() {
    guard let emacsMajorVersion = findEmacsMajorVersion() else {
      XCTFail("Couldn't find appropriate emacs")
      return
    }
    print("Running integration tests against Emacs \(emacsMajorVersion)")

    cd("TestModule")
    guard isExecutableInPath("cask"),
          runCaskInstall(),
          let loadPath = runCaskLoadPath() else {
      XCTFail("Integration tests require Cask")
      return
    }

    let buildType: String
    #if DEBUG
      buildType = "debug"
    #elseif RELEASE
      buildType = "release"
    #else
      XCTFail("Unknown build type")
    #endif

    guard runSwiftBuild(buildType) else {
      XCTFail("TestModule build has failed")
      return
    }

    XCTAssert(runTests(emacsMajorVersion, buildType: buildType, loadPath: loadPath),
              "Emacs integrations tests have failed")
  }
}
