//
//  ExpandFolders.swift
//  CucumberSwiftLintPlugin
//
// CucumberSwiftTestingPlugin compiles this file too, through a symlink: plugins can't share a library.

import Foundation

/// `path` if it is a file, and every file inside it, at any depth, if it is a folder, leaving out
/// `.build` folders. Feature files are usually a copied resource folder, so plugins are given the
/// folder, not the files in it.
func expand(_ path: String) -> [String] {
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) else { return [] }
    guard isDirectory.boolValue else { return [path] }
    guard let enumerator = FileManager.default.enumerator(atPath: path) else { return [] }
    return enumerator.compactMap { $0 as? String }
        .filter { !$0.hasPrefix(".build/") && !$0.contains("/.build/") }
        .map { URL(fileURLWithPath: path).appendingPathComponent($0).path }
}
