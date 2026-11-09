#!/usr/bin/env python3
"""Check the Cucumber JSON report a fixture's test run wrote.

A test run writes one report, whichever runners its test targets use (#546).
So `mise run test-fixtures` gives a fixture that has an expected-report file a
report path of its own, runs its tests, and checks the report with this script,
from the repository's root folder. The report comes on the standard input:

  python3 .github/scripts/fixture_report.py check <fixture> expected-report < <report>

The fixture is the name of a folder in Fixtures/. Each line of its expected
file, other than comments and blank lines, names a feature the report must
have, with at least one scenario. The report must have no other feature, so a
feature an earlier run left in it fails the check.

A fixture can also have an expected-report-rerun file. Its first lines, other
than comments and blank lines, are `<key>: <value>` settings, and the rest name
features as above. The task then runs the fixture's tests again, straight after
the first run, and checks the report against that file: the new run must
replace the first run's report, not add to it.

  tags: <tags>              a Swift package: `swift test` with CUCUMBER_TAGS set
                            to the tags. `swift test --filter` can't choose the
                            XCTest runner's scenarios, whose test classes exist
                            only while the tests run.
  only-testing: <target>    an Xcode project: `xcodebuild test` of the scheme
                            with -only-testing:<target>.

  python3 .github/scripts/fixture_report.py get <fixture> <expected file> <key>

prints a setting of an expected file: expected-report or expected-report-rerun.

The expected-report file of a Swift package fixture whose test run ages the
report has `ages-report: <suffix>`. The fixture's first runner writes the file
`<report><suffix>` as it exits, after it sets the report's age to 2 hours, so
that the next runner starts when the report is stale. The task checks that the
file is there. The next runner must still keep the report: the features of both
runners are in it. Only the standard library is used.
"""
import json
import os
import sys

FIXTURES = "Fixtures"
EXPECTED_FILES = ("expected-report", "expected-report-rerun")
SETTINGS = ("tags", "only-testing", "ages-report")


def expected_file(fixture, kind, root=FIXTURES):
    """The path of a fixture's expected file, built from the entries of the fixtures' folder and the names of
    the expected files, so that no argument becomes part of a path."""
    for folder in os.listdir(root):
        if folder == fixture:
            for name in EXPECTED_FILES:
                if name == kind:
                    return os.path.join(root, folder, name)
    raise ValueError(f"{fixture}/{kind}: there is no such fixture in {root}, or the file isn't {' or '.join(EXPECTED_FILES)}")


def expectation(path):
    """The settings, as a dictionary, and the feature names an expected file gives."""
    with open(path, encoding="utf-8") as file:
        stripped = (line.strip() for line in file)
        names = [line for line in stripped if line and not line.startswith("#")]
    settings = {}
    while names and names[0].partition(":")[0] in SETTINGS:
        key, _, value = names.pop(0).partition(":")
        if not value.strip():
            raise ValueError(f"{path}: `{key}:` gives no value")
        settings[key] = value.strip()
    if not names:
        raise ValueError(f"{path}: names no feature")
    return settings, names


def problems(expected, report):
    """What's wrong with the report's features, as messages; none when it has exactly the expected ones."""
    if not isinstance(report, list):
        return ["the report isn't a list of features"]
    found = {}
    for feature in report:
        name = feature.get("name") if isinstance(feature, dict) else None
        scenarios = feature.get("elements") if isinstance(feature, dict) else None
        found[name] = found.get(name, 0) + (len(scenarios) if isinstance(scenarios, list) else 0)
    messages = []
    for name in expected:
        if name not in found:
            messages.append(f"the report has no feature {name!r}")
        elif found[name] == 0:
            messages.append(f"the report's feature {name!r} has no scenarios")
    for name in found:
        if name not in expected:
            messages.append(f"the report has a feature it shouldn't: {name!r}")
    return messages


def run(argv, stdin, root=FIXTURES):
    if len(argv) == 5 and argv[1] == "get":
        path = expected_file(argv[2], argv[3], root)
        settings, _ = expectation(path)
        if argv[4] not in settings:
            print(f"error: {path}: has no `{argv[4]}:` setting")
            return 1
        print(settings[argv[4]])
        return 0
    if len(argv) != 4 or argv[1] != "check":
        print(__doc__)
        return 2
    path = expected_file(argv[2], argv[3], root)
    _, expected = expectation(path)
    try:
        report = json.load(stdin)
    except ValueError as error:
        print(f"error: {path}: can't read the report on the standard input: {error}")
        return 1
    messages = problems(expected, report)
    for message in messages:
        print(f"error: {path}: {message}")
    if messages:
        return 1
    features = "feature" if len(expected) == 1 else "features"
    print(f"{path}: the report has the {len(expected)} {features} it lists, and no other.")
    return 0


def main(argv):
    try:
        return run(argv, sys.stdin)
    except ValueError as error:
        print(f"error: {error}")
        return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
