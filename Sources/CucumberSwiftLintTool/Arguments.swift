/// `--stamp <file> --features <file>… --step-definitions <file>…`, or `--fix <file or folder>…`
struct Arguments {
    private static let options: Set = ["--stamp", "--features", "--step-definitions", "--fix"]

    private(set) var stamp: String?
    private(set) var features = [String]()
    private(set) var swiftFiles = [String]()
    /// Whether to fix the feature files in `fixPaths` rather than check them.
    private(set) var fix = false
    private(set) var fixPaths = [String]()

    init<S: Sequence>(_ arguments: S) where S.Element == String {
        var option: String?
        for argument in arguments {
            // Only these names, so a file whose path starts with "--" is still read as a file.
            if Self.options.contains(argument) {
                option = argument
                fix = fix || argument == "--fix"
                continue
            }
            switch option {
                case "--stamp": stamp = argument
                case "--features": features.append(argument)
                case "--step-definitions": swiftFiles.append(argument)
                case "--fix": fixPaths.append(argument)
                default: break
            }
        }
    }
}
