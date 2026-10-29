//
//  ProfileCounters.swift
//  CucumberSwift
//
//  Shared with CucumberSwiftTesting through the Sources/CucumberSwiftTesting/Coverage symlink, so it
//  uses neither XCTest nor Swift Testing.
//

import Foundation
#if canImport(MachO)
import MachO
#endif

/// The code coverage counters of the binaries in this process that were built with code coverage, and
/// the profile runtime linked into each of them.
///
/// The compiler links a copy of LLVM's profile runtime into every binary it builds with coverage, such as
/// the test bundle and an app that hosts it. Each copy counts only its own binary's code and writes only
/// its own binary's counters, so CucumberSwift handles each binary on its own.
///
/// A scenario's coverage is what its counters gained while it ran. ``snapshot()`` copies every counter
/// when the scenario starts, and ``writeProfiles(named:in:since:)`` writes the difference when it ends. The
/// counters keep their totals, so the coverage report that Xcode or `swift test` builds at the end of the
/// run is unchanged.
struct ProfileCounters {
    /// A binary built with code coverage, and its profile runtime.
    struct Binary {
        let path: String
        let uuid: String?
        fileprivate let counters: UnsafeMutableRawBufferPointer
        fileprivate let writeFile: @convention(c) () -> Int32
        fileprivate let setFilename: @convention(c) (UnsafePointer<CChar>?) -> Void
    }

    /// Every binary's counters at one moment.
    struct Snapshot {
        fileprivate let counts: [[UInt8]]

        /// The copied counters, one array of bytes for each binary.
        var countsForTesting: [[UInt8]] { counts }
    }

    enum WriteError: Error, Equatable {
        /// `LLVM_PROFILE_FILE` has `%c`: the runtime keeps writing to that file, and can't write another.
        case continuousMode
        case writeFailed(binary: String)
    }

    let binaries: [Binary]

    /// The binaries loaded now that were built with code coverage. Empty when none was, or on a platform
    /// without Mach-O.
    static func loaded() -> ProfileCounters {
        #if canImport(MachO)
        var binaries = [Binary]()
        for index in 0..<_dyld_image_count() {
            guard let header = _dyld_get_image_header(index), header.pointee.magic == MH_MAGIC_64,
                  let path = _dyld_get_image_name(index).map({ String(cString: $0) }) else { continue }
            let image = MachImage(header: UnsafeRawPointer(header), slide: _dyld_get_image_vmaddr_slide(index))
            guard let counters = image.section(segment: "__DATA", name: "__llvm_prf_cnts"),
                  let writeFile = image.localFunction("___llvm_profile_write_file"),
                  let setFilename = image.localFunction("___llvm_profile_set_filename") else { continue }
            binaries.append(Binary(path: path, uuid: image.uuid, counters: counters,
                                   writeFile: unsafeBitCast(writeFile, to: (@convention(c) () -> Int32).self),
                                   setFilename: unsafeBitCast(setFilename, to: (@convention(c) (UnsafePointer<CChar>?) -> Void).self)))
        }
        return ProfileCounters(binaries: binaries)
        #else
        return ProfileCounters(binaries: [])
        #endif
    }

    func snapshot() -> Snapshot {
        Snapshot(counts: binaries.map { [UInt8]($0.counters) })
    }

    /// Writes what each binary's counters gained since `snapshot`, as one `.profraw` file for each binary,
    /// named `<name>-<binary file name>.profraw`, in `folder`. Returns the files' names.
    ///
    /// The counters contain the difference only while the runtime writes it, and get their totals back
    /// before this returns. Code running on another thread meanwhile may be counted in the scenario.
    func writeProfiles(named name: String, in folder: URL, since snapshot: Snapshot,
                       environment: [String: String] = ProcessInfo.processInfo.environment) throws -> [String] {
        let pattern = environment["LLVM_PROFILE_FILE"]
        if pattern?.contains("%c") == true { throw WriteError.continuousMode }
        var files = [String]()
        for (binary, before) in zip(binaries, snapshot.counts) where binary.counters.count == before.count {
            let file = "\(name)-\(URL(fileURLWithPath: binary.path).lastPathComponent).profraw"
            Self.subtract(before, from: binary.counters)
            defer { Self.add(before, to: binary.counters) }
            let written = folder.appendingPathComponent(file).path.withCString { path -> Int32 in
                binary.setFilename(path)
                defer {
                    // Back to where Xcode or `swift test` expects the run's own profile.
                    (pattern ?? "default.profraw").withCString { binary.setFilename($0) }
                }
                return binary.writeFile()
            }
            guard written == 0 else { throw WriteError.writeFailed(binary: binary.path) }
            files.append(file)
        }
        return files
    }

    /// Subtracts the snapshot's 64-bit counts from the live ones.
    static func subtract(_ before: [UInt8], from counters: UnsafeMutableRawBufferPointer) {
        let count = counters.count / 8
        for index in 0..<count {
            let now = counters.loadUnaligned(fromByteOffset: index * 8, as: UInt64.self)
            let then = before.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: index * 8, as: UInt64.self) }
            counters.storeBytes(of: now >= then ? now - then : 0, toByteOffset: index * 8, as: UInt64.self)
        }
    }

    /// Adds the snapshot's 64-bit counts back to the live ones.
    static func add(_ before: [UInt8], to counters: UnsafeMutableRawBufferPointer) {
        let count = counters.count / 8
        for index in 0..<count {
            let now = counters.loadUnaligned(fromByteOffset: index * 8, as: UInt64.self)
            let then = before.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: index * 8, as: UInt64.self) }
            counters.storeBytes(of: now &+ then, toByteOffset: index * 8, as: UInt64.self)
        }
    }
}

#if canImport(MachO)
/// Reads a loaded 64-bit Mach-O image: its sections, its UUID, and the private functions in its symbol
/// table, which `dlsym` can't find.
struct MachImage {
    let header: UnsafeRawPointer
    let slide: Int

    private var loadCommands: [UnsafeRawPointer] {
        let header = self.header.assumingMemoryBound(to: mach_header_64.self).pointee
        var command = self.header + MemoryLayout<mach_header_64>.size
        var commands = [UnsafeRawPointer]()
        for _ in 0..<header.ncmds {
            commands.append(command)
            command += Int(command.load(as: load_command.self).cmdsize)
        }
        return commands
    }

    func section(segment: String, name: String) -> UnsafeMutableRawBufferPointer? {
        var size: UInt = 0
        let header64 = header.assumingMemoryBound(to: mach_header_64.self)
        guard let start = getsectiondata(header64, segment, name, &size), size > 0 else { return nil }
        return UnsafeMutableRawBufferPointer(start: start, count: Int(size))
    }

    var uuid: String? {
        for command in loadCommands where command.load(as: load_command.self).cmd == UInt32(LC_UUID) {
            let uuid = command.load(as: uuid_command.self).uuid
            return UUID(uuid: uuid).uuidString
        }
        return nil
    }

    /// The address of a function in the image's symbol table, local symbols included.
    func localFunction(_ symbol: String) -> UnsafeRawPointer? {
        var linkEdit: segment_command_64?
        var symtab: symtab_command?
        for command in loadCommands {
            switch command.load(as: load_command.self).cmd {
                case UInt32(LC_SEGMENT_64):
                    let segment = command.load(as: segment_command_64.self)
                    if Self.name(of: segment.segname) == SEG_LINKEDIT { linkEdit = segment }
                case UInt32(LC_SYMTAB):
                    symtab = command.load(as: symtab_command.self)
                default:
                    break
            }
        }
        guard let linkEdit, let symtab,
              let linkEditBase = UnsafeRawPointer(bitPattern: Int(linkEdit.vmaddr) + slide - Int(linkEdit.fileoff)) else { return nil }
        let symbols = linkEditBase + Int(symtab.symoff)
        let strings = (linkEditBase + Int(symtab.stroff)).assumingMemoryBound(to: CChar.self)
        for index in 0..<Int(symtab.nsyms) {
            let entry = symbols.loadUnaligned(fromByteOffset: index * MemoryLayout<nlist_64>.size, as: nlist_64.self)
            // A defined symbol in a section, not a debugging entry.
            guard entry.n_type & UInt8(N_STAB) == 0, entry.n_type & UInt8(N_TYPE) == UInt8(N_SECT),
                  strcmp(strings + Int(entry.n_un.n_strx), symbol) == 0 else { continue }
            return UnsafeRawPointer(bitPattern: Int(entry.n_value) + slide)
        }
        return nil
    }

    /// A fixed-size C string, such as a segment's name, which Swift imports as a tuple of characters.
    private static func name<CString>(of characters: CString) -> String {
        withUnsafeBytes(of: characters) { String(decoding: $0.prefix { $0 != 0 }, as: UTF8.self) }
    }
}
#endif
