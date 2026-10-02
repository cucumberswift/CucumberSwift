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
        let failures: [WriteError]
    }

    /// A feature file whose fixes couldn't be saved.
    struct WriteError: Error, CustomStringConvertible {
        let file: String
        let reason: String

        var description: String { "\(file): error: Couldn't save the fixes: \(reason)" }
    }

    private static let byteOrderMark = Data([0xEF, 0xBB, 0xBF])
    // Each pass can turn a description into steps, which are checked more closely, so a file is
    // checked again after each pass. A few passes are always enough.
    private static let maximumPasses = 10

    /// Fixes the feature files in `paths`, each a `.feature` file or a folder to search, and
    /// returns what it changed and which files it couldn't save.
    static func fix(paths: [String]) -> Outcome {
        let files = featureFiles(in: paths)
        var changes = [Change]()
        var failures = [WriteError]()
        for file in files {
            do {
                changes += try fix(file: file)
            } catch let error as WriteError {
                failures.append(error)
            } catch {
                failures.append(WriteError(file: file, reason: error.localizedDescription))
            }
        }
        return Outcome(files: files, changes: changes, failures: failures)
    }

    /// Fixes one feature file, and returns what it changed. A file with nothing to fix is not
    /// written to. Throws a `WriteError` if the fixes can't be saved.
    static func fix(file: String) throws -> [Change] {
        guard var data = FileManager.default.contents(atPath: file) else { return [] }
        // Foundation drops a byte order mark when it decodes, so keep it to write back.
        let hasByteOrderMark = data.starts(with: byteOrderMark)
        if hasByteOrderMark { data.removeFirst(byteOrderMark.count) }
        guard var contents = String(data: data, encoding: .utf8) else { return [] }
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
            throw WriteError(file: file, reason: error.localizedDescription)
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

    /// The `.feature` files in `paths`, searching folders but not hidden ones such as `.build`.
    static func featureFiles(in paths: [String]) -> [String] {
        var files = Set<String>()
        for path in paths {
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) else { continue }
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
        return files.sorted()
    }
}
