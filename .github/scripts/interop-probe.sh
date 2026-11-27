#!/bin/bash
# Temporary probe for #562, removed after one run: what each SWIFT_TESTING_XCTEST_INTEROP_MODE does to a
# failure from the other test framework, under `swift test` and under xcodebuild (macOS only). It runs a bare
# package and the BrokenFeaturesPackage fixture, whose Swift Testing target it gives an XCTAssert scenario
# first, on this runner's checkout only. Each run's matching lines go to the log, and every full log to $1.
set -u
out=$1
root=$(pwd)
mkdir -p "$out/bare/Tests/ProbeTests"

cat > "$out/bare/Package.swift" <<'EOF'
// swift-tools-version:6.1
import PackageDescription
let package = Package(name: "Probe", platforms: [.macOS(.v14)], targets: [.testTarget(name: "ProbeTests")])
EOF
cat > "$out/bare/Tests/ProbeTests/Probe.swift" <<'EOF'
import Testing
import XCTest

final class XCTestSide: XCTestCase {
    func testExpectInXCTest() { #expect(1 == 2, "PROBE expect in XCTest") }
    func testIssueInXCTest() { Issue.record("PROBE issue in XCTest") }
}

@Test func xctFailInSwiftTesting() { XCTFail("PROBE XCTFail in Swift Testing") }
@Test func xctAssertInSwiftTesting() { XCTAssertEqual(1, 2, "PROBE XCTAssert in Swift Testing") }
EOF

fixture="$root/Fixtures/BrokenFeaturesPackage"
python3 - "$fixture/Tests/BrokenSwiftTestingTests" <<'EOF'
import sys
d = sys.argv[1]
p = d + "/StepDefinitions.swift"
s = open(p).read()
s = s.replace("import Testing\n", "import Testing\nimport XCTest\n", 1)
s = s.replace('        When("an expectation fails")',
              '        When("an XCTest assertion fails") { _, _ in XCTAssertEqual(1, 2, "XCTAssert failed on purpose") }\n'
              '        When("an expectation fails")', 1)
open(p, "w").write(s)
p = d + "/Features/Assertions.feature"
s = open(p).read()
s = s.replace("Feature: Failing assertions\n",
              "Feature: Failing assertions\n  Scenario: An XCTest assertion fails its step\n"
              "    When an XCTest assertion fails\n    Then the step after a failed assertion never runs\n\n", 1)
open(p, "w").write(s)
EOF

bare_lines='PROBE|Executed [0-9]+ tests|Test run with|Fatal error'
fixture_lines='Assertions\.feature:[0-9]+: error|Test "(An|A) [^"]*" recorded|Test "(An|A) [^"]*" with [0-9]+ test cases|Assertions.feature:[0-9]+: -\[.*skipped|after a failed assertion ran|Executed 1[0-9] tests|Test run with|Fatal error'

probe() { # name, package directory, scheme, lines
  local name=$1 dir=$2 scheme=$3 lines=$4 mode driver log
  (cd "$dir" && swift build --build-tests) > "$out/$name-swift-build.log" 2>&1 || echo "::warning::$name: swift build failed"
  (cd "$dir" && xcodebuild build-for-testing -scheme "$scheme" -destination 'platform=macOS' \
    -derivedDataPath "$out/$name-dd") > "$out/$name-xcodebuild-build.log" 2>&1 \
    || echo "::warning::$name: xcodebuild build-for-testing failed"
  for mode in unset none limited complete strict; do
    for driver in swift-test xcodebuild; do
      log="$out/$name-$mode-$driver.log"
      if [ "$driver" = swift-test ]; then
        if [ "$mode" = unset ]; then
          (cd "$dir" && swift test --skip-build) > "$log" 2>&1
        else
          (cd "$dir" && SWIFT_TESTING_XCTEST_INTEROP_MODE=$mode swift test --skip-build) > "$log" 2>&1
        fi
      else
        if [ "$mode" = unset ]; then
          (cd "$dir" && xcodebuild test-without-building -scheme "$scheme" -destination 'platform=macOS' \
            -derivedDataPath "$out/$name-dd") > "$log" 2>&1
        else
          (cd "$dir" && TEST_RUNNER_SWIFT_TESTING_XCTEST_INTEROP_MODE=$mode xcodebuild test-without-building \
            -scheme "$scheme" -destination 'platform=macOS' -derivedDataPath "$out/$name-dd") > "$log" 2>&1
        fi
      fi
      echo "===== $name | mode=$mode | $driver | exit $?"
      grep -E "$lines" "$log" | sed -E "s#$root/##g; s#$out/##g; s#^.*/Features/##" | cut -c1-300 | sort -u
    done
  done
}

probe bare "$out/bare" Probe-Package "$bare_lines"
probe fixture "$fixture" BrokenFeaturesPackage-Package "$fixture_lines"
