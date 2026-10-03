/// A problem found in a feature file or a step definition, printed in the form Xcode and SwiftPM
/// show as a warning on that line.
struct Diagnostic: CustomStringConvertible, Equatable {
    /// Replaces `text`, which starts at the diagnostic's line and column, with `replacement`.
    struct Fix: Equatable {
        let text: String
        let replacement: String
    }

    let file: String
    let line: Int
    var column = 1
    let message: String
    /// The change that the "Did you mean" suggestion in `message` describes, if it has one.
    var fix: Fix?

    var description: String { "\(file):\(line):\(column): warning: \(message)" }
}
