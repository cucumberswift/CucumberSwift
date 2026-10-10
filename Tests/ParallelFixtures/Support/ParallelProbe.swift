// LOCAL PROBE for #389 research. Never commit.
import Foundation
import XCTest

enum ParallelProbe {
    static var observer: Observer?

    static func dump(_ label: String, extra: [String: String] = [:]) {
        guard let folder = ProcessInfo.processInfo.environment["PROBE_DIR"] ?? ProcessInfo.processInfo.environment["PARALLEL_TEST_RECORDS"].map({ $0 + "-probe" }),
              !folder.isEmpty else { return }
        let info = ProcessInfo.processInfo
        var lines = [String]()
        lines.append("label=\(label)")
        lines.append("pid=\(info.processIdentifier) ppid=\(getppid()) name=\(info.processName)")
        lines.append("mainBundle=\(Bundle.main.bundleIdentifier ?? "nil") path=\(Bundle.main.bundlePath)")
        lines.append("args=\(info.arguments)")
        extra.sorted { $0.key < $1.key }.forEach { lines.append("extra.\($0.key)=\($0.value)") }
        for (key, value) in info.environment.sorted(by: { $0.key < $1.key }) {
            lines.append("env.\(key)=\(value)")
        }
        lines.append(contentsOf: configuration())
        let dir = URL(fileURLWithPath: folder, isDirectory: true)
        let sandbox = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("parallel-probe")
        for candidate in [dir, sandbox] {
            do {
                try FileManager.default.createDirectory(at: candidate, withIntermediateDirectories: true)
                try lines.joined(separator: "\n").write(to: candidate.appendingPathComponent("\(label).\(info.processIdentifier).\(UUID().uuidString).txt"), atomically: true, encoding: .utf8)
                return
            } catch { continue }
        }
    }

    static func configuration() -> [String] {
        guard let cls = NSClassFromString("XCTestConfiguration") as? NSObject.Type else { return ["config=no class"] }
        let sel = NSSelectorFromString("activeTestConfiguration")
        var methods = [String]()
        var n: UInt32 = 0
        if let list = class_copyMethodList(object_getClass(cls), &n) {
            for i in 0..<Int(n) { methods.append(NSStringFromSelector(method_getName(list[i]))) }
            free(list)
        }
        let classMethods = "config.classMethods=\(methods.sorted())"
        guard cls.responds(to: sel), let config = cls.perform(sel)?.takeUnretainedValue() as? NSObject else { return ["config=none", classMethods] }
        var out = ["config.class=\(type(of: config))"]
        var c: AnyClass? = object_getClass(config)
        while let current = c, current != NSObject.self {
            var count: UInt32 = 0
            if let props = class_copyPropertyList(current, &count) {
                for i in 0..<Int(count) {
                    let name = String(cString: property_getName(props[i]))
                    guard config.responds(to: NSSelectorFromString(name)) else { continue }
                    let value = config.value(forKey: name).map { String(describing: $0) } ?? "nil"
                    out.append("config.\(name)=\(value.replacingOccurrences(of: "\n", with: " ").prefix(600))")
                }
                free(props)
            }
            c = class_getSuperclass(current)
        }
        return out
    }

    final class Observer: NSObject, XCTestObservation {
        func testBundleWillStart(_ testBundle: Bundle) {
            ParallelProbe.dump("bundleWillStart")
        }
        func testSuiteWillStart(_ testSuite: XCTestSuite) {
            if testSuite.name.contains("xctest") || testSuite.name.hasPrefix("All") || testSuite.name.hasPrefix("Selected") {
                ParallelProbe.dump("suiteWillStart", extra: ["suite": testSuite.name, "count": "\(testSuite.testCaseCount)",
                                                             "children": testSuite.tests.prefix(40).map(\.name).joined(separator: ",")])
            }
        }
    }

    static func start() {
        dump("setupSteps")
        DispatchQueue.main.async { dump("mainAsync") }
        let path = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] ?? ""
        if !path.isEmpty, let data = FileManager.default.contents(atPath: path),
           let object = (try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data)) as? NSObject {
            dump("configFile", extra: ["testsDrivenByIDE": "\(object.value(forKey: "testsDrivenByIDE") ?? "nil")"])
        } else {
            dump("configFile", extra: ["path": path, "readable": "\(FileManager.default.isReadableFile(atPath: path))"])
        }
        if observer == nil {
            let o = Observer()
            observer = o
            XCTestObservationCenter.shared.addTestObserver(o)
        }
    }
}
