//
//  FeatureSourceFiles.swift
//  CucumberSwift
//
// Where the XCTest runner reports an issue about a feature file: the feature file in the project, as the Swift
// Testing runner does, not the copy in the test bundle that it read. A feature's `uri`, in the JSON report and
// for hooks and observers, stays the copy's URL, as with the Swift Testing runner.

import Foundation

enum FeatureSourceFiles {
    private struct State {
        var featuresFolder: URL?
        var copies = [URL]()
        var stepDefinitionFiles = Set<String>()
        /// Each copy's project file, by the copy's path, once worked out.
        var projectFiles: [String: URL]?
    }

    /// The paths of a target's feature files in the project, which the CucumberSwiftLint plugin recorded.
    struct RecordedPaths: Equatable {
        let target: String
        let paths: [String]
    }

    /// The start of the Objective-C name of the class that the CucumberSwiftLint plugin adds to each target, with
    /// its feature files' paths in the project. Keep it the same as `FeatureSourcePaths.classNamePrefix` in
    /// CucumberSwiftLintTool.
    static let recordedPathsClassNamePrefix = "CucumberSwiftFeatureSourcePaths_"

    /// Files and folders in a project that the search for feature files doesn't enter: build products, such
    /// as the copies in a test bundle, and folders of dependencies.
    private static let skippedFolderExtensions: Set = [
        "app", "appex", "bundle", "framework", "xcarchive", "xcodeproj", "xcresult", "xctest", "xcworkspace"
    ]
    private static let skippedFolderNames: Set = ["DerivedData", "node_modules", "Pods", "Carthage"]
    /// Files and folders that mark a project's root folder, above which the search doesn't go.
    private static let projectRootFiles: Set = [
        ".git", "MODULE.bazel", "Package.swift", "Project.swift", "WORKSPACE", "WORKSPACE.bazel"
    ]
    private static let projectRootExtensions: Set = ["xcodeproj", "xcworkspace"]
    private static let state = Locked(State())

    /// Sets the feature files the runner read: `copies`, in the test bundle's `featuresFolder`.
    static func read(copies: [URL], in featuresFolder: URL) {
        state.withLock {
            $0.featuresFolder = featuresFolder
            $0.copies = copies
            $0.projectFiles = nil
        }
    }

    /// Notes the Swift file of a step definition, `#filePath`, for finding the project's feature files without
    /// the plugin.
    static func addStepDefinition(file: StaticString) {
        let path = "\(file)"
        guard path.hasPrefix("/") else { return }
        state.withLock {
            if $0.stepDefinitionFiles.insert(path).inserted {
                $0.projectFiles = nil
            }
        }
    }

    /// Where to report an issue about the feature file whose copy in the test bundle is at `url`: the project's
    /// feature file, if it can be found, else `url`.
    static func issueFile(for url: URL) -> URL {
        guard url.isFileURL else { return url }
        let projectFiles = state.withLock { current -> [String: URL] in
            if let projectFiles = current.projectFiles { return projectFiles }
            let projectFiles = current.featuresFolder.map { folder in
                find(copies: current.copies,
                     in: folder,
                     recordedPaths: recordedPaths(for: folder, among: recordedPaths()),
                     stepDefinitionFiles: Array(current.stepDefinitionFiles))
            } ?? [:]
            current.projectFiles = projectFiles
            return projectFiles
        }
        return projectFiles[url.standardizedFileURL.path] ?? url
    }

    /// The paths that the CucumberSwiftLint plugin recorded for each target when the tests built, from the
    /// classes it added to the targets. Found by name among every loaded class, since a Swift package's test
    /// bundle may be a resource bundle, without code.
    static func recordedPaths() -> [RecordedPaths] {
        let capacity = objc_getClassList(nil, 0)
        guard capacity > 0 else { return [] }
        let classes = UnsafeMutablePointer<AnyClass>.allocate(capacity: Int(capacity))
        defer { classes.deallocate() }
        let count = min(objc_getClassList(AutoreleasingUnsafeMutablePointer(classes), capacity), capacity)
        return (0..<Int(count)).compactMap { index -> RecordedPaths? in
            // Only the name, until it matches: touching some classes runs code, or traps.
            guard String(cString: class_getName(classes[index])).hasPrefix(recordedPathsClassNamePrefix),
                  let type = classes[index] as? NSObject.Type,
                  let target = value(of: "target", in: type) as? String,
                  let paths = value(of: "paths", in: type) as? [String] else { return nil }
            return RecordedPaths(target: target, paths: paths)
        }
    }

    private static func value(of property: String, in type: NSObject.Type) -> Any? {
        let selector = NSSelectorFromString(property)
        guard type.responds(to: selector) else { return nil }
        return type.perform(selector)?.takeUnretainedValue()
    }

    /// The recorded paths of the target whose test bundle has `featuresFolder`: the only target's, else the one
    /// the bundle is named after, as `<target>.xctest`, or `<package>_<target>.bundle` in a Swift package. `nil`
    /// when there are none, or it's not clear which.
    static func recordedPaths(for featuresFolder: URL, among recorded: [RecordedPaths]) -> [String]? {
        if recorded.count < 2 { return recorded.first?.paths }
        let bundleNames = featuresFolder.pathComponents
            .filter { ["app", "bundle", "xctest"].contains(URL(fileURLWithPath: $0).pathExtension) }
            .map { URL(fileURLWithPath: $0).deletingPathExtension().lastPathComponent }
        let named = recorded.filter { target in
            bundleNames.contains { $0 == target.target || $0.hasSuffix("_" + target.target) }
        }
        return named.count == 1 ? named.first?.paths : nil
    }

    /// Each copy's project file, by the copy's path: from the plugin's `recordedPaths` of the copies' target, else
    /// found from the folders of `stepDefinitionFiles`.
    static func find(copies: [URL], in featuresFolder: URL, recordedPaths: [String]?, stepDefinitionFiles: [String]) -> [String: URL] {
        if let recordedPaths {
            return match(copies: copies, in: featuresFolder, recordedPaths: recordedPaths)
        }
        return search(copies: copies, in: featuresFolder, stepDefinitionFiles: stepDefinitionFiles)
    }

    /// Each copy's project file among `recordedPaths`: the one whose copy it is, as the Swift Testing runner
    /// pairs them (`TestBundleFiles.bundledFeatureFile`). A copy that more than one path pairs with keeps none.
    static func match(copies: [URL], in featuresFolder: URL, recordedPaths: [String]) -> [String: URL] {
        var sources = [String: [String]]()
        for path in recordedPaths {
            let copy = TestBundleFiles.bundledFeatureFile(forSourcePath: path, in: featuresFolder, files: copies)
            sources[copy.standardizedFileURL.path, default: []].append(path)
        }
        return sources.compactMapValues { paths in
            paths.count == 1 ? paths.first.map { URL(fileURLWithPath: $0) } : nil
        }
    }

    /// Each copy's project file, found from the folder of each step definition's Swift file: the feature files
    /// whose paths end with the copy's path in `featuresFolder`, in the nearest folder up to the project's root
    /// that has any. A copy keeps none unless exactly one is found.
    static func search(copies: [URL], in featuresFolder: URL, stepDefinitionFiles: [String]) -> [String: URL] {
        // Paths with symbolic links resolved, as the file system's enumerator gives them.
        let folderComponents = featuresFolder.resolvingSymlinksInPath().pathComponents
        // Each step definition's folder and the folders above it, up to and including the project's root.
        let ancestorLists = Set(stepDefinitionFiles.map { URL(fileURLWithPath: $0).deletingLastPathComponent().resolvingSymlinksInPath().path })
            .compactMap(foldersUpToProjectRoot)
        var featureFilesByRoot = [String: [String]]()
        for root in Set(ancestorLists.compactMap(\.last)) {
            featureFilesByRoot[root] = featureFiles(under: root)
        }
        var projectFiles = [String: URL]()
        for copy in copies {
            let components = copy.resolvingSymlinksInPath().pathComponents
            let relative = Array(components.starts(with: folderComponents) ? components.dropFirst(folderComponents.count) : components.suffix(1))
            guard !relative.isEmpty else { continue }
            let suffix = "/" + relative.joined(separator: "/")
            var found = Set<String>()
            for folders in ancestorLists {
                guard let root = folders.last, let files = featureFilesByRoot[root] else { continue }
                for folder in folders {
                    let matches = files.filter { $0.hasPrefix(folder + "/") && $0.hasSuffix(suffix) }
                    if !matches.isEmpty {
                        found.formUnion(matches)
                        break
                    }
                }
            }
            if found.count == 1, let path = found.first {
                projectFiles[copy.standardizedFileURL.path] = URL(fileURLWithPath: path)
            }
        }
        return projectFiles
    }

    /// `folder` and each folder above it, up to the first that is a project's root, or `nil` when none above it is.
    private static func foldersUpToProjectRoot(from folder: String) -> [String]? {
        var folders = [String]()
        var url = URL(fileURLWithPath: folder, isDirectory: true)
        while url.path != "/" {
            folders.append(url.path)
            if isProjectRoot(url) { return folders }
            url = url.deletingLastPathComponent()
        }
        return nil
    }

    private static func isProjectRoot(_ folder: URL) -> Bool {
        guard let names = try? FileManager.default.contentsOfDirectory(atPath: folder.path) else { return false }
        return names.contains { projectRootFiles.contains($0) || projectRootExtensions.contains(URL(fileURLWithPath: $0).pathExtension) }
    }

    /// The paths of the `.feature` files under `folder`, outside hidden folders, build products and dependencies.
    private static func featureFiles(under folder: String) -> [String] {
        guard let enumerator = FileManager.default.enumerator(at: URL(fileURLWithPath: folder, isDirectory: true),
                                                              includingPropertiesForKeys: [.isDirectoryKey],
                                                              options: [.skipsHiddenFiles, .skipsPackageDescendants]) else { return [] }
        var files = [String]()
        while let url = enumerator.nextObject() as? URL {
            if (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
                if skippedFolderExtensions.contains(url.pathExtension) || skippedFolderNames.contains(url.lastPathComponent) {
                    enumerator.skipDescendants()
                }
            } else if url.pathExtension == "feature" {
                files.append(url.resolvingSymlinksInPath().path)
            }
        }
        return files
    }
}
