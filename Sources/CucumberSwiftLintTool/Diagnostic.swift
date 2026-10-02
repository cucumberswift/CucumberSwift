/// A problem found in a feature file or a step definition, printed in the form Xcode and SwiftPM
/// show as a warning on that line.
struct Diagnostic: CustomStringConvertible, Equatable {
    let file: String
    let line: Int
    var column = 1
    let message: String

    var description: String { "\(file):\(line):\(column): warning: \(message)" }
}
