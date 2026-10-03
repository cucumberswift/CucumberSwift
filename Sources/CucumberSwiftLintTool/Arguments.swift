/// `--stamp <file> --features <file>… --step-definitions <file>…`
struct Arguments {
    private static let options: Set = ["--stamp", "--features", "--step-definitions"]

    private(set) var stamp: String?
    private(set) var features = [String]()
    private(set) var swiftFiles = [String]()

    init<S: Sequence>(_ arguments: S) where S.Element == String {
        var option: String?
        for argument in arguments {
            // Only these names, so a file whose path starts with "--" is still read as a file.
            if Self.options.contains(argument) {
                option = argument
                continue
            }
            switch option {
                case "--stamp": stamp = argument
                case "--features": features.append(argument)
                case "--step-definitions": swiftFiles.append(argument)
                default: break
            }
        }
    }
}
