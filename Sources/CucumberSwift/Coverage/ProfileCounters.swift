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

/// The layout of a version of LLVM's raw profile format, as `InstrProfData.inc` defines it in the LLVM of
/// the Xcode that uses it. The profile runtime builds a binary's `__llvm_prf_data` records with the same
/// layout, so the version also says how to read them.
struct RawProfileFormat: Equatable {
    /// Version 8: Xcode 16.0 to 16.2, whose Swift 6.0 uses LLVM 17. A record holds the name's hash, the
    /// function's hash, the counters' address relative to the record, the function's address, its values,
    /// its counter count and 2 counts of value sites.
    static let version8 = RawProfileFormat(version: 8, recordSize: 48, valueSites: 44..<48)
    /// Version 10: Xcode 16.3 and later, Xcode 26 included. A record adds the bitmap's address after the
    /// counters' and its size at the end, and has 3 counts of value sites.
    static let version10 = RawProfileFormat(version: 10, recordSize: 64, valueSites: 52..<58)

    /// Every version that CucumberSwift writes.
    static let all = [version8, version10]

    /// The version, as the low 32 bits of `__llvm_profile_raw_version` hold it.
    let version: UInt64
    /// The size of a `__llvm_prf_data` record, padded to 8 bytes.
    let recordSize: Int
    /// Where a record's counts of value sites are, which come after its 32-bit counter count.
    let valueSites: Range<Int>

    /// Whether the header describes a bitmap, which version 9 added for MC/DC coverage.
    var hasBitmap: Bool { version >= 9 }
    /// Whether the header counts virtual tables, which version 10 added.
    var hasVirtualTables: Bool { version >= 10 }
    /// The last kind of value that a profile can hold, the header's last word. Version 10 added
    /// virtual table targets to the 2 kinds before.
    var valueKindLast: UInt64 { hasVirtualTables ? 2 : 1 }

    /// The format of a binary's raw profile `version`, as `__llvm_profile_raw_version` holds it: the low
    /// bytes hold the version, and the high bits flags for the kind of profile. Nil for another version.
    init?(version: UInt64) {
        guard let format = Self.all.first(where: { $0.version == version & 0xFFFF_FFFF }) else { return nil }
        self = format
    }

    private init(version: UInt64, recordSize: Int, valueSites: Range<Int>) {
        self.version = version
        self.recordSize = recordSize
        self.valueSites = valueSites
    }
}

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
        /// The layout of that version.
        fileprivate let format: RawProfileFormat
        #if canImport(Compression)
        /// The binary's coverage map, which the scores need. Nil when it can't be read, as
        /// ``mapProblem`` says.
        var map: CoverageMap?
        #endif
        /// Why the binary has no coverage map.
        var mapProblem: String?
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

    private(set) var binaries: [Binary]
    /// The raw profile versions of the binaries that were built with code coverage but that
    /// CucumberSwift doesn't write.
    private(set) var unsupportedVersions = [UInt64]()

    /// Whether a binary loaded now was built with code coverage. It only looks for the counters' section,
    /// so it is cheap: `auto` coverage asks it before deciding to measure.
    static var isInstrumented: Bool {
        #if canImport(MachO)
        return (0..<_dyld_image_count()).contains { index in
            _dyld_get_image_header(index).map { header in
                // Only 64-bit images, as `loaded()` reads.
                header.pointee.magic == MH_MAGIC_64
                    && MachImage(header: UnsafeRawPointer(header), slide: _dyld_get_image_vmaddr_slide(index))
                        .section(segment: "__DATA", name: "__llvm_prf_cnts") != nil
            } ?? false
        }
        #else
        return false
        #endif
    }

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
            guard counters.accept(version: version), let format = RawProfileFormat(version: version) else { continue }
            var binary = Binary(
                path: path,
                uuid: image.uuid,
                counters: cnts,
                data: UnsafeRawBufferPointer(data),
                names: UnsafeRawBufferPointer(names),
                bitmap: image.section(segment: "__DATA", name: "__llvm_prf_bits", allowsEmpty: true).map { UnsafeRawBufferPointer($0) }
                    ?? UnsafeRawBufferPointer(start: nil, count: 0),
                version: version,
                format: format
            )
            #if canImport(Compression)
            if let covmap = image.section(segment: "__LLVM_COV", name: "__llvm_covmap"),
               let covfun = image.section(segment: "__LLVM_COV", name: "__llvm_covfun") {
                do {
                    binary.map = try CoverageMap(covmap: UnsafeRawBufferPointer(covmap),
                                                 covfun: UnsafeRawBufferPointer(covfun),
                                                 data: binary.data,
                                                 counters: UnsafeRawBufferPointer(cnts),
                                                 names: binary.names,
                                                 recordSize: format.recordSize)
                } catch {
                    binary.mapProblem = "\(URL(fileURLWithPath: path).lastPathComponent): \(error)"
                }
            } else {
                binary.mapProblem = "\(URL(fileURLWithPath: path).lastPathComponent) has no coverage map"
            }
            #else
            binary.mapProblem = "this platform can't read coverage maps"
            #endif
            counters.binaries.append(binary)
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

    /// Whether CucumberSwift writes a binary's raw profile `version`, as `__llvm_profile_raw_version` holds
    /// it: the low bytes hold the version, and the high bits flags for the kind of profile. Remembers a
    /// version that it doesn't write.
    mutating func accept(version: UInt64) -> Bool {
        guard RawProfileFormat(version: version) != nil else {
            unsupportedVersions.append(version & 0xFFFF_FFFF)
            return false
        }
        return true
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
        try writeProfiles(named: name, in: folder, counts: differences(since: snapshot))
    }

    /// What each binary's counters gained since `snapshot`, one array of bytes for each binary, empty for a
    /// binary whose counters changed size.
    func differences(since snapshot: Snapshot) -> [[UInt8]] {
        zip(binaries, snapshot.counts).map { binary, before in
            binary.counters.count == before.count ? Self.difference([UInt8](binary.counters), minus: before) : []
        }
    }

    /// Writes `counts`, from ``differences(since:)``, as ``writeProfiles(named:in:since:)`` does.
    func writeProfiles(named name: String, in folder: URL, counts: [[UInt8]]) throws -> [String] {
        var files = [String]()
        for (binary, gained) in zip(binaries, counts) where binary.counters.count == gained.count {
            let file = "\(name)-\(URL(fileURLWithPath: binary.path).lastPathComponent).profraw"
            let profile = binary.rawProfile(counters: gained)
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
    /// The raw profile of `counters`, as ``RawProfileFormat/rawProfile(version:data:countersSection:counters:bitmap:names:)``
    /// lays it out for the binary's version.
    func rawProfile(counters: [UInt8]) -> Data {
        format.rawProfile(version: version,
                          data: data,
                          countersSection: UnsafeRawBufferPointer(self.counters),
                          counters: counters,
                          bitmap: bitmap,
                          names: names)
    }
}

extension RawProfileFormat {
    /// The raw profile of `counters`, laid out as the profile runtime of this version lays out its own: the
    /// header's 64-bit words, the data records, the counters, the bitmap bytes, if the version has them, and
    /// the names, each padded to 8 bytes. `llvm-profdata` reads it as it reads the runtime's.
    ///
    /// `version` is the binary's `__llvm_profile_raw_version`, flags included. `data`, `bitmap` and `names`
    /// are the binary's sections, and `countersSection` its counters, which locate `counters` as the header
    /// gives it.
    func rawProfile(version: UInt64,
                    data: UnsafeRawBufferPointer,
                    countersSection: UnsafeRawBufferPointer,
                    counters: [UInt8],
                    bitmap: UnsafeRawBufferPointer,
                    names: UnsafeRawBufferPointer) -> Data {
        func padding(_ size: Int) -> Int { (8 - size % 8) % 8 }
        let address = { (buffer: UnsafeRawBufferPointer) in UInt64(UInt(bitPattern: buffer.baseAddress)) }

        // The magic number, "\xFFlprofr\x81", the version, the size of the binary IDs, which this profile
        // has none of, the records' count, the padding before the counters, their count and the padding after.
        var header: [UInt64] = [0xFF6C_7072_6F66_7281, version, 0, UInt64(data.count / recordSize), 0, UInt64(counters.count / 8), 0]
        if hasBitmap {
            header += [UInt64(bitmap.count), UInt64(padding(bitmap.count))]
        }
        header.append(UInt64(names.count))
        // The counters and the bitmap are located relative to the data, and the names by their address.
        header.append(address(countersSection) &- address(data))
        if hasBitmap {
            header.append(bitmap.baseAddress == nil ? 0 : address(bitmap) &- address(data))
        }
        header.append(address(names))
        if hasVirtualTables {
            header += [0, 0] // The virtual tables' count and the size of their names.
        }
        header.append(valueKindLast)

        var records = [UInt8](data.prefix(data.count / recordSize * recordSize))
        // A record's counts of value sites, which this profile has no data for.
        for record in stride(from: 0, to: records.count, by: recordSize) {
            for byte in valueSites { records[record + byte] = 0 }
        }

        var profile = Data()
        header.withUnsafeBytes { profile.append(contentsOf: $0) }
        profile.append(contentsOf: records)
        profile.append(contentsOf: counters)
        if hasBitmap {
            profile.append(contentsOf: bitmap)
            profile.append(contentsOf: [UInt8](repeating: 0, count: padding(bitmap.count)))
        }
        profile.append(contentsOf: names)
        profile.append(contentsOf: [UInt8](repeating: 0, count: padding(names.count)))
        return profile
    }
}
