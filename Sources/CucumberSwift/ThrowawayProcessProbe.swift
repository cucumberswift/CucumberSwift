import Foundation

// Throwaway proof for #600: Process does not exist on watchOS or tvOS. Reverted right after.
enum ThrowawayProcessProbe {
    static func run() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/true")
        try? process.run()
    }
}
