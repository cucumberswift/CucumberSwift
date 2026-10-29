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

#if canImport(MachO)
/// Reads a loaded 64-bit Mach-O image: its sections, its UUID, and the private symbols in its symbol
/// table, which `dlsym` can't find.
struct MachImage {
    let header: UnsafeRawPointer
    let slide: Int

    var uuid: String? {
        for command in loadCommands where command.load(as: load_command.self).cmd == UInt32(LC_UUID) {
            let uuid = command.load(as: uuid_command.self).uuid
            return UUID(uuid: uuid).uuidString
        }
        return nil
    }

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

    /// A fixed-size C string, such as a segment's name, which Swift imports as a tuple of characters.
    private static func name<CString>(of characters: CString) -> String {
        withUnsafeBytes(of: characters) { String(bytes: $0.prefix { $0 != 0 }, encoding: .utf8) ?? "" }
    }

    /// The bytes of a section, or nil if the image has none. A section can be empty and still have an
    /// address, as the bitmap of a binary with no branches does, and the raw profile records it.
    func section(segment: String, name: String, allowsEmpty: Bool = false) -> UnsafeMutableRawBufferPointer? {
        var size: UInt = 0
        let header64 = header.assumingMemoryBound(to: mach_header_64.self)
        guard let start = getsectiondata(header64, segment, name, &size), size > 0 || allowsEmpty else { return nil }
        return UnsafeMutableRawBufferPointer(start: start, count: Int(size))
    }

    /// The address of a symbol in the image's symbol table, local symbols included.
    func localSymbol(_ symbol: String) -> UnsafeRawPointer? {
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
}
#endif

/// The code coverage counters of the binaries in this process that were built with code coverage.
///
/// The compiler puts counters into every binary it builds with coverage, such as the test bundle, a
/// framework and an app that hosts the tests. Each binary counts only its own code, so CucumberSwift
/// handles each binary on its own.
///
/// A scenario's coverage is what its counters gained while it ran. ``snapshot()`` copies every counter
/// when the scenario starts, and ``writeProfiles(named:in:since:)`` writes the difference when
/// it ends. The counters keep their totals, so the coverage report that Xcode or `swift test` builds at the
/// end of the run is unchanged.
struct ProfileCounters {
    /// A binary built with code coverage: its counters, and the sections the raw profile needs to describe them.
    struct Binary {
        let path: String
        let uuid: String?
        fileprivate let counters: UnsafeMutableRawBufferPointer
        fileprivate let data: UnsafeRawBufferPointer
        fileprivate let names: UnsafeRawBufferPointer
        fileprivate let bitmap: UnsafeRawBufferPointer
        /// The profile runtime's raw profile version of this binary, as `__llvm_profile_raw_version` holds it.
        fileprivate let version: UInt64
    }

    /// Every binary's counters at one moment.
    struct Snapshot {
        fileprivate let counts: [[UInt8]]

        /// The copied counters, one array of bytes for each binary.
        var countsForTesting: [[UInt8]] { counts }
    }

    enum WriteError: Error, Equatable {
        case writeFailed(binary: String)
    }

    /// The raw profile version that CucumberSwift writes: the one that Xcode 26's LLVM uses. A binary
    /// built with another version is left out, and listed in ``unsupportedVersions``.
    static let supportedVersion: UInt64 = 10

    private(set) var binaries: [Binary]
    /// The raw profile versions of the binaries that were built with code coverage but that
    /// CucumberSwift doesn't write.
    private(set) var unsupportedVersions = [UInt64]()

    /// The binaries loaded now that were built with code coverage. Empty when none was, or on a platform
    /// without Mach-O.
    static func loaded() -> ProfileCounters {
        #if canImport(MachO)
        var counters = ProfileCounters(binaries: [])
        for index in 0..<_dyld_image_count() {
            guard let header = _dyld_get_image_header(index), header.pointee.magic == MH_MAGIC_64,
                  let path = _dyld_get_image_name(index).map({ String(cString: $0) }) else { continue }
            let image = MachImage(header: UnsafeRawPointer(header), slide: _dyld_get_image_vmaddr_slide(index))
            guard let cnts = image.section(segment: "__DATA", name: "__llvm_prf_cnts"),
                  let data = image.section(segment: "__DATA", name: "__llvm_prf_data"),
                  let names = image.section(segment: "__DATA", name: "__llvm_prf_names"),
                  let versionAddress = image.localSymbol("___llvm_profile_raw_version") else { continue }
            let version = versionAddress.load(as: UInt64.self)
            // The low bytes hold the version, and the high bits flags for the kind of profile.
            guard version & 0xFFFF_FFFF == supportedVersion else {
                counters.unsupportedVersions.append(version & 0xFFFF_FFFF)
                continue
            }
            counters.binaries.append(Binary(
                path: path,
                uuid: image.uuid,
                counters: cnts,
                data: UnsafeRawBufferPointer(data),
                names: UnsafeRawBufferPointer(names),
                bitmap: image.section(segment: "__DATA", name: "__llvm_prf_bits", allowsEmpty: true).map { UnsafeRawBufferPointer($0) }
                    ?? UnsafeRawBufferPointer(start: nil, count: 0),
                version: version
            ))
        }
        return counters
        #else
        return ProfileCounters(binaries: [])
        #endif
    }

    /// The 64-bit counts in `now` minus those in `before`. A count that went down, which only happens if
    /// the counters were reset meanwhile, is 0.
    static func difference(_ now: [UInt8], minus before: [UInt8]) -> [UInt8] {
        var result = now
        result.withUnsafeMutableBytes { counters in
            before.withUnsafeBytes { then in
                for index in 0..<(counters.count / 8) {
                    let current = counters.loadUnaligned(fromByteOffset: index * 8, as: UInt64.self)
                    let earlier = then.loadUnaligned(fromByteOffset: index * 8, as: UInt64.self)
                    counters.storeBytes(of: current >= earlier ? current - earlier : 0, toByteOffset: index * 8, as: UInt64.self)
                }
            }
        }
        return result
    }

    func snapshot() -> Snapshot {
        Snapshot(counts: binaries.map { [UInt8]($0.counters) })
    }

    /// Writes what each binary's counters gained since `snapshot`, as one `.profraw` file for each binary,
    /// named `<name>-<binary file name>.profraw`, in `folder`. Returns the files' names.
    ///
    /// CucumberSwift writes the raw profile itself, from the binary's sections, and never calls the
    /// profile runtime: the linker can remove the runtime's functions, as Xcode does by default in a
    /// project with dead code stripping on. It works in every mode of the runtime, including the
    /// continuous mode (`%c` in `LLVM_PROFILE_FILE`), and leaves the run's own profile as it is.
    func writeProfiles(named name: String, in folder: URL, since snapshot: Snapshot) throws -> [String] {
        var files = [String]()
        for (binary, before) in zip(binaries, snapshot.counts) where binary.counters.count == before.count {
            let file = "\(name)-\(URL(fileURLWithPath: binary.path).lastPathComponent).profraw"
            let profile = binary.rawProfile(counters: Self.difference([UInt8](binary.counters), minus: before))
            do {
                try profile.write(to: folder.appendingPathComponent(file))
            } catch {
                throw WriteError.writeFailed(binary: binary.path)
            }
            files.append(file)
        }
        return files
    }
}

extension ProfileCounters.Binary {
    /// The raw profile of `counters`, laid out as the profile runtime lays out its own: a header of 16
    /// 64-bit words, the data records, the counters, the bitmap bytes, and the names, each padded to 8 bytes.
    /// `llvm-profdata` reads it as it reads the runtime's.
    func rawProfile(counters: [UInt8]) -> Data {
        let recordSize = 64
        func padding(_ size: Int) -> Int { (8 - size % 8) % 8 }
        let address = { (buffer: UnsafeRawBufferPointer) in UInt64(UInt(bitPattern: buffer.baseAddress)) }

        var header = [UInt64](repeating: 0, count: 16)
        header[0] = 0xFF6C_7072_6F66_7281 // "\xFFlprofr\x81"
        header[1] = version
        header[3] = UInt64(data.count / recordSize)
        header[5] = UInt64(counters.count / 8)
        header[7] = UInt64(bitmap.count)
        header[8] = UInt64(padding(bitmap.count))
        header[9] = UInt64(names.count)
        // The counters and the bitmap are located relative to the data, and the names by their address.
        header[10] = address(UnsafeRawBufferPointer(self.counters)) &- address(data)
        header[11] = bitmap.baseAddress == nil ? 0 : address(bitmap) &- address(data)
        header[12] = address(names)
        header[15] = 2 // The last kind of value that a profile can hold.

        var records = [UInt8](data)
        // A record's three counts of value sites, which this profile has no data for, come after its
        // 32-bit counter count at byte 48.
        for record in stride(from: 0, to: records.count, by: recordSize) {
            for byte in (record + 52)..<(record + 58) { records[byte] = 0 }
        }

        var profile = Data()
        header.withUnsafeBytes { profile.append(contentsOf: $0) }
        profile.append(contentsOf: records)
        profile.append(contentsOf: counters)
        profile.append(contentsOf: bitmap)
        profile.append(contentsOf: [UInt8](repeating: 0, count: padding(bitmap.count)))
        profile.append(contentsOf: names)
        profile.append(contentsOf: [UInt8](repeating: 0, count: padding(names.count)))
        return profile
    }
}
