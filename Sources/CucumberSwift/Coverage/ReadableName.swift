//
//  ReadableName.swift
//  CucumberSwift
//
//  Shared with CucumberSwiftTesting through the Sources/CucumberSwiftTesting/Coverage symlink.
//

import Foundation

/// A function's name as a message can show it, from the name the profile gives it.
enum ReadableName {
    private typealias Demangle = @convention(c) (UnsafePointer<CChar>, Int, UnsafeMutablePointer<CChar>?, UnsafeMutablePointer<Int>?, UInt32) -> UnsafeMutablePointer<CChar>?

    /// The Swift runtime's demangler, which it exports for tools.
    private static let demangle: Demangle? = {
        guard let handle = dlopen(nil, RTLD_NOW), let symbol = dlsym(handle, "swift_demangle") else { return nil }
        return unsafeBitCast(symbol, to: Demangle.self)
    }()

    /// `name` demangled and shortened, such as `Calculator.classify(Int)` for the name of
    /// `Calculator.classify(_:)` in the module `Calculator`. A name that isn't a Swift name stays as it is.
    static func of(_ name: String) -> String {
        // The profile prefixes a private function's name with its file and a colon.
        let mangled = name.range(of: "$s").map { String(name[$0.lowerBound...]) } ?? name
        guard mangled.hasPrefix("$s"), let demangle,
              let demangled = mangled.withCString({ demangle($0, strlen($0), nil, nil, 0) }) else { return name }
        defer { free(demangled) }
        return shortened(String(cString: demangled))
    }

    /// A demangled name without its module, the `Swift.` of standard types, or what follows its
    /// parameters, such as `throws` and its result type.
    static func shortened(_ name: String) -> String {
        var name = name
        if let open = name.firstIndex(of: "(") {
            var depth = 0
            for index in name[open...].indices {
                if name[index] == "(" { depth += 1 }
                if name[index] == ")" { depth -= 1 }
                if depth == 0 {
                    name = String(name[...index])
                    break
                }
            }
        }
        name = name.replacingOccurrences(of: "Swift.", with: "")
        // The module is the first part of the name, when the name has another before its parameters.
        let beforeParameters = name.split(separator: "(", maxSplits: 1).first.map(String.init) ?? name
        if let dot = beforeParameters.firstIndex(of: "."), !beforeParameters.contains(" ") {
            name = String(name[name.index(after: dot)...])
        }
        return name
    }
}
