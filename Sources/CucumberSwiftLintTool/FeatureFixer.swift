import Foundation

/// Fixes misspelt keywords in `.feature` files by applying the "Did you mean" suggestions that
/// `FeatureChecker` reports, so it only ever changes what the build plugin warns about.
enum FeatureFixer {
    /// A line that was fixed, printed as `file:line: before → after`.
    struct Change: CustomStringConvertible, Equatable {
        let file: String
        let line: Int
        let before: String
        let after: String

        var description: String { "\(file):\(line): \(before) → \(after)" }
    }

    /// What fixing a set of feature files did.
    struct Outcome {
        let files: [String]
        let changes: [Change]
        let failures: [Failure]
    }

    /// A requested path or feature file that couldn't be checked or fixed.
    struct Failure: Error, CustomStringConvertible, Equatable {
        let file: String
        let reason: String

        var description: String { "\(file): error: \(reason)" }
    }

    private static let byteOrderMark = Data([0xEF, 0xBB, 0xBF])
    // Each pass can turn a description into steps, which are checked more closely, so a file is
    // checked again after each pass. A few passes are always enough.
    private static let maximumPasses = 10

    /// Fixes the feature files in `paths`, prints each change and then a summary to `output`, and
    /// each failure to `errorOutput`. Returns the exit status: 1 if any path or file couldn't be
    /// checked or fixed, so that the command fails rather than report success.
    static func run(paths: [String], output: (String) -> Void, errorOutput: (String) -> Void) -> Int32 {
        let outcome = fix(paths: paths)
        outcome.changes.forEach { output($0.description) }
        outcome.failures.forEach { errorOutput($0.description) }
        let files = outcome.files.count
        let plural = files == 1 ? "" : "s"
        if outcome.changes.isEmpty {
            output(outcome.failures.isEmpty ? "Nothing to fix in \(files) feature file\(plural)." : "Fixed nothing.")
        } else {
            let lines = outcome.changes.count
            let fixedFiles = Set(outcome.changes.map(\.file)).count
            output("Fixed \(lines) line\(lines == 1 ? "" : "s") in \(fixedFiles) of \(files) feature file\(plural).")
        }
        return outcome.failures.isEmpty ? 0 : 1
    }

    /// Fixes the feature files in `paths`, each a `.feature` file or a folder to search, and
    /// returns what it changed and what it couldn't check or fix.
    static func fix(paths: [String]) -> Outcome {
        let found = featureFiles(in: paths)
        var changes = [Change]()
        var failures = found.missing.map { Failure(file: $0, reason: "No such feature file or folder") }
        for file in found.files {
            do {
                changes += try fix(file: file)
            } catch let failure as Failure {
                failures.append(failure)
            } catch {
                failures.append(Failure(file: file, reason: error.localizedDescription))
            }
        }
        return Outcome(files: found.files, changes: changes, failures: failures)
    }

    /// Fixes one feature file, and returns what it changed. A file with nothing to fix is not
    /// written to. Throws a `Failure` if the file can't be read, isn't UTF-8, or can't be saved.
    static func fix(file: String) throws -> [Change] {
        guard var data = FileManager.default.contents(atPath: file) else {
            throw Failure(file: file, reason: "Couldn't read this feature file")
        }
        // Foundation drops a byte order mark when it decodes, so keep it to write back.
        let hasByteOrderMark = data.starts(with: byteOrderMark)
        if hasByteOrderMark { data.removeFirst(byteOrderMark.count) }
        guard var contents = String(data: data, encoding: .utf8) else {
            throw Failure(file: file, reason: "This feature file isn't UTF-8 text, so it wasn't checked")
        }
        var changes = [Int: Change]()
        for _ in 0..<maximumPasses {
            let pass = fixOnce(contents, file: file)
            guard !pass.changes.isEmpty else { break }
            contents = pass.contents
            for change in pass.changes {
                let before = changes[change.line]?.before ?? change.before
                changes[change.line] = Change(file: file, line: change.line, before: before, after: change.after)
            }
        }
        guard !changes.isEmpty else { return [] }
        let fixed = (hasByteOrderMark ? byteOrderMark : Data()) + Data(contents.utf8)
        do {
            try fixed.write(to: URL(fileURLWithPath: file))
        } catch {
            throw Failure(file: file, reason: "Couldn't save the fixes: \(error.localizedDescription)")
        }
        return changes.values.sorted { $0.line < $1.line }
    }

    /// Applies every fix the checker reports for `contents` once.
    private static func fixOnce(_ contents: String, file: String) -> (contents: String, changes: [Change]) {
        var fixes = [Diagnostic]()
        FeatureChecker(file: file, definitions: nil).check(contents: contents) { diagnostic in
            if diagnostic.fix != nil { fixes.append(diagnostic) }
        }
        // Split on "\n" alone, so a "\r" at the end of a line is kept as it was.
        var lines = contents.components(separatedBy: "\n")
        var changes = [Change]()
        for diagnostic in fixes {
            guard let fix = diagnostic.fix, lines.indices.contains(diagnostic.line - 1) else { continue }
            let before = lines[diagnostic.line - 1]
            guard let after = apply(fix, to: before, at: diagnostic.column) else { continue }
            lines[diagnostic.line - 1] = after
            changes.append(Change(file: file, line: diagnostic.line, before: trimmed(before), after: trimmed(after)))
        }
        return (lines.joined(separator: "\n"), changes)
    }

    /// `line` with `fix` applied at the 1-based `column`, or nil if the text there isn't what the
    /// fix expects.
    private static func apply(_ fix: Diagnostic.Fix, to line: String, at column: Int) -> String? {
        guard column >= 1, column - 1 <= line.count else { return nil }
        let start = line.index(line.startIndex, offsetBy: column - 1)
        guard line[start...].hasPrefix(fix.text) else { return nil }
        var result = line
        result.replaceSubrange(start..<line.index(start, offsetBy: fix.text.count), with: fix.replacement)
        return result
    }

    private static func trimmed(_ line: String) -> String {
        line.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The `.feature` files in `paths`, searching folders but not hidden ones such as `.build`,
    /// and the paths that don't exist.
    static func featureFiles(in paths: [String]) -> (files: [String], missing: [String]) {
        var files = Set<String>()
        var missing = [String]()
        for path in paths {
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) else {
                missing.append(path)
                continue
            }
            let url = URL(fileURLWithPath: path)
            guard isDirectory.boolValue else {
                if url.pathExtension == "feature" { files.insert(url.standardizedFileURL.path) }
                continue
            }
            let contents = FileManager.default.enumerator(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            while let file = contents?.nextObject() as? URL {
                if file.pathExtension == "feature" { files.insert(file.standardizedFileURL.path) }
            }
        }
        return (files.sorted(), missing)
    }
}
