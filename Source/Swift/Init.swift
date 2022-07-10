import Cocoa
import EmacsModule
import SwiftUI

@_cdecl("plugin_is_GPL_compatible")
public func isGPLCompatible() -> Int32 {
  return 1
}

struct ContentView: View {
  let callback: () -> Void
  init(callback: @escaping () -> Void) {
    self.callback = callback
  }

  var body: some View {
    Button("OK", action: callback)
      .padding()
      .frame(width: 100.0)
  }
}

extension NSViewController: OpaquelyEmacsConvertible {}

@_cdecl("emacs_module_init")
public func Init(_ runtimePtr: UnsafeMutablePointer<emacs_runtime>) -> Int32 {
  let env = Environment(from: runtimePtr)
  env.defn(named: "swift-test", with: "") { (arg: String) in
    "I received \(arg)!!"
  }
  env.defn(named: "swift-add-button", with: "Add fancy button") {
    (env: Environment) -> NSViewController in
    let newController = NSHostingController(rootView: ContentView {})
    if let view = NSApp.windows[0].contentView {
      view.addSubview(newController.view)
      newController.view.frame = NSMakeRect(300, 300, 100, 50)
    }
    return newController
  }
  env.defn(named: "swift-remove-button", with: "Remove fancy button") {
    (toRemove: NSViewController) -> String in
    toRemove.removeFromParent()
    toRemove.view.removeFromSuperview()
    return "Success"
  }

  return 0
}
