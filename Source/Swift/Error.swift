enum EmacsError: Error {
  case nonASCIISymbol(value: String)
}
