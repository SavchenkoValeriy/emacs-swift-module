import EmacsModule

protocol EmacsConvertible {
    func convert(within env: Environment) -> EmacsValue
    static func convert(from: EmacsValue, within env: Environment) -> Self
}

extension String: EmacsConvertible {
    func convert(within env: Environment) -> EmacsValue {
        return env.make(self)
    }

    static func convert(from: EmacsValue, within env: Environment) -> String {
        return env.toString(from)
    }
}

extension Environment {
    //
    // Value factories
    //
    public func make(_ from: String) -> EmacsValue {
        return EmacsValue(from: raw.pointee.make_string(raw, from, from.count))
    }

    //
    // Converter functions
    //
    public func toString(_ value: EmacsValue) -> String {
        var len = 0
        let _ = raw.pointee.copy_string_contents(raw, value.raw, nil, &len)
        var buf = [CChar](repeating: 0, count: len)
        let _ = raw.pointee.copy_string_contents(raw, value.raw, &buf, &len)
        return String(cString: buf)
    }
}
