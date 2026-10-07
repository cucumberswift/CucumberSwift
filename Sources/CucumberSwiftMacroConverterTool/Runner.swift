//
//  Runner.swift
//  CucumberSwiftMacroConverterTool
//

#if Macros
import SwiftSyntax

/// The runner a file imports, which decides the macros' module and whether localized macros exist.
struct Runner {
    struct Found {
        /// `CucumberSwift` or `CucumberSwiftTesting`.
        let module: String
        let macrosModule: String
        let importsMacros: Bool
        var hasLocalizedMacros: Bool { module == "CucumberSwift" }
    }

    let found: Found?
    /// Why no step definition in the file can be converted, when the imports don't say which runner it uses.
    let problem: String?

    init(importsOf tree: SourceFileSyntax) {
        let modules = Set(ImportCollector(viewMode: .sourceAccurate).modules(in: tree))
        let runners = [("CucumberSwift", "CucumberSwiftMacros"), ("CucumberSwiftTesting", "CucumberSwiftTestingMacros")]
            .filter { modules.contains($0.0) || modules.contains($0.1) }
        switch runners.count {
            case 1:
                let (module, macrosModule) = runners[0]
                found = Found(module: module, macrosModule: macrosModule, importsMacros: modules.contains(macrosModule))
                problem = nil
            case 0:
                found = nil
                problem = "the file imports neither CucumberSwift nor CucumberSwiftTesting, so it isn't clear which macros to use"
            default:
                found = nil
                problem = "the file imports both CucumberSwift and CucumberSwiftTesting, so it isn't clear which macros to use"
        }
    }
}
#endif
