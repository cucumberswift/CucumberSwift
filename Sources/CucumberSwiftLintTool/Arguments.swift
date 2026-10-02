/// `--stamp <file> --features <file>… --step-definitions <file>…`
struct Arguments {
    private(set) var stamp: String?
    private(set) var features = [String]()
    private(set) var swiftFiles = [String]()

    init<S: Sequence>(_ arguments: S) where S.Element == String {
        var option: String?
        for argument in arguments {
            if argument.hasPrefix("--") {
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
