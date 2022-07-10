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

@_cdecl("emacs_module_init")
public func Init(_ runtimePtr: UnsafeMutablePointer<emacs_runtime>) -> Int32 {
  let env = Environment(from: runtimePtr)
  env.defn(named: "swift-test", with: "") { (arg: String) in
    "I received \(arg)!!"
  }
  let newController = NSHostingController(
    rootView: ContentView {})
  if let view = NSApp.windows[0].contentView {
    view.addSubview(newController.view)
    newController.view.frame = NSMakeRect(300, 200, 100, 50)
  }
  return 0
}
