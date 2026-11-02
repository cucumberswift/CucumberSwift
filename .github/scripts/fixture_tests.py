#!/usr/bin/env python3
"""Check that a fixture's tests ran, as many as its expected-tests file lists.

A test run can exit with success having run nothing: in #509, Xcode's test
harness crashed, Xcode ran the bundle again with 0 tests and reported TEST
SUCCEEDED. So `mise run test-fixtures` and `mise run test-carthage` check the
output of each fixture's `swift test` or `xcodebuild test` with this script:

  python3 .github/scripts/fixture_tests.py <fixture folder> <output file>

Each fixture in Fixtures/ has an expected-tests file. Each of its lines, other
than comments and blank lines, gives the fewest tests one test framework must
run:

  XCTest: 61
  Swift Testing: 6

The count of a framework is the sum of its runs' summaries in the output:

  XCTest         the `Executed N tests` line after each
                 `Test Suite 'All tests' passed` or `failed` line;
  Swift Testing  each `Test run with N tests` line.

For CucumberSwift's XCTest runner, each step of a scenario is a test. For its
Swift Testing runner, each scenario or outline is a test.

The check fails, with a message that names the fixture and both counts, when a
framework ran fewer tests than its line gives, or ran tests the file does not
list. It also fails when the fixture has no expected-tests file, or the file
lists nothing or has a line it cannot read.

Only the standard library is used.
"""
import os
import re
import sys

FRAMEWORKS = ("XCTest", "Swift Testing")

ALL_TESTS = re.compile(r"^Test Suite 'All tests' (passed|failed) at ")
EXECUTED = re.compile(r"^\s*Executed (\d+) tests?, ")
TEST_RUN = re.compile(r"Test run with (\d+) tests? ")
LINE = re.compile(r"^(XCTest|Swift Testing):\s*(\d+)$")


class ExpectedTestsError(Exception):
    """An expected-tests file that is missing or cannot be read."""


def read_expected(path):
    """Return {framework: fewest tests} from an expected-tests file."""
    if not os.path.isfile(path):
        raise ExpectedTestsError("has no expected-tests file")
    expected = {}
    with open(path, encoding="utf-8") as f:
        for number, line in enumerate(f, start=1):
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            match = LINE.match(line)
            if not match:
                raise ExpectedTestsError(
                    f"expected-tests line {number} isn't `XCTest: <count>` "
                    f"or `Swift Testing: <count>`: {line}")
            framework = match.group(1)
            if framework in expected:
                raise ExpectedTestsError(
                    f"expected-tests lists {framework} twice")
            expected[framework] = int(match.group(2))
    if not expected:
        raise ExpectedTestsError("expected-tests lists no tests")
    return expected


def count_tests(output):
    """Return {framework: tests run} from a test run's output."""
    counts = {framework: 0 for framework in FRAMEWORKS}
    after_all_tests = False
    for line in output.splitlines():
        if after_all_tests:
            match = EXECUTED.match(line)
            if match:
                counts["XCTest"] += int(match.group(1))
            after_all_tests = False
        if ALL_TESTS.match(line):
            after_all_tests = True
        match = TEST_RUN.search(line)
        if match:
            counts["Swift Testing"] += int(match.group(1))
    return counts


def check(name, expected, counts):
    """Return the errors for a fixture's counts against its expected counts."""
    errors = []
    for framework in FRAMEWORKS:
        ran = counts.get(framework, 0)
        if framework in expected:
            if ran < expected[framework]:
                errors.append(
                    f"error: {name}: ran {ran} {framework} tests, fewer than "
                    f"the {expected[framework]} expected-tests requires")
        elif ran > 0:
            errors.append(
                f"error: {name}: ran {ran} {framework} tests, which "
                f"expected-tests doesn't list")
    return errors


def main(argv):
    if len(argv) != 3:
        print("usage: fixture_tests.py <fixture folder> <output file>",
              file=sys.stderr)
        return 2
    fixture, log = argv[1], argv[2]
    name = os.path.basename(os.path.normpath(fixture))
    try:
        expected = read_expected(os.path.join(fixture, "expected-tests"))
    except ExpectedTestsError as error:
        print(f"error: {name}: {error}", file=sys.stderr)
        return 1
    with open(log, encoding="utf-8", errors="replace") as f:
        counts = count_tests(f.read())
    errors = check(name, expected, counts)
    for error in errors:
        print(error, file=sys.stderr)
    if errors:
        return 1
    ran = " and ".join(f"{counts[framework]} {framework}"
                       for framework in FRAMEWORKS if framework in expected)
    print(f"{name}: ran {ran} tests, as many as expected-tests requires.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
