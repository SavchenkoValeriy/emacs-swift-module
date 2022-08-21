/// Emacs dynamic module, @main class of your package.
public protocol Module {
  /// Every dynamic module should be distributed under the GPL compatible license.
  ///
  /// By returning true here, you agree that your module follows this rule.
  var isGPLCompatible: Bool { get }
  /// Module initialization point.
  ///
  /// This function gets executed only once when the user loads the module from Emacs. Usually the module defines some package-specific functions here and/or creates the channel of communication with Emacs.
  ///
  /// When this function finishes its execution, the given environment becomes invalid and shouldn't be used. See <doc:Lifetimes> for more details.
  func Init(_ env: Environment) throws
}
