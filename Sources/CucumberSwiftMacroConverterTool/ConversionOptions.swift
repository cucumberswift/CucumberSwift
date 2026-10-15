//
//  ConversionOptions.swift
//  CucumberSwiftMacroConverterTool
//

#if Macros
/// What the command line says: files and folders to convert, `--path` files and folders the user chose,
/// `--dry-run`, and what the plugin found out about the project: its folder, and each target that uses
/// CucumberSwift without the macros product.
struct ConversionOptions {
    var dryRun = false
    var root: String?
    var missingMacrosProducts = [(target: String, product: String)]()
    var paths = [String]()
    /// What `--path` named, as typed: relative to `root`, and checked to be inside it.
    var chosenPaths = [String]()

    init(_ arguments: [String]) {
        var remaining = arguments.makeIterator()
        while let argument = remaining.next() {
            switch argument {
                case "--dry-run":
                    dryRun = true
                case "--root":
                    root = remaining.next()
                case "--path":
                    if let value = remaining.next() { chosenPaths.append(value) }
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
