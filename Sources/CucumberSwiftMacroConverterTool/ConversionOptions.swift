//
//  ConversionOptions.swift
//  CucumberSwiftMacroConverterTool
//

#if Macros
/// What the command line says: files and folders to convert, `--dry-run`, and what the plugin found out about
/// the project: its folder, and each target that uses CucumberSwift without the macros product.
struct ConversionOptions {
    var dryRun = false
    var root: String?
    var missingMacrosProducts = [(target: String, product: String)]()
    var paths = [String]()

    init(_ arguments: [String]) {
        var remaining = arguments.makeIterator()
        while let argument = remaining.next() {
            switch argument {
                case "--dry-run":
                    dryRun = true
                case "--root":
                    root = remaining.next()
                case "--missing-macros":
                    if let value = remaining.next(), let separator = value.firstIndex(of: "=") {
                        missingMacrosProducts.append((String(value[..<separator]), String(value[value.index(after: separator)...])))
                    }
                default:
                    paths.append(argument)
            }
        }
    }
}
#endif
