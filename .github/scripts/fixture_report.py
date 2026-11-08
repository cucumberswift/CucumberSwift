#!/usr/bin/env python3
"""Check the Cucumber JSON report a fixture's test run wrote.

A test run writes one report, whichever runners its test targets use (#546).
So `mise run test-fixtures` gives a fixture that has an expected-report file a
report path of its own, runs its tests, and checks the report with this script:

  python3 .github/scripts/fixture_report.py check <expected file> <report>

Each line of the expected file, other than comments and blank lines, names a
feature the report must have, with at least one scenario. The report must have
no other feature, so a feature an earlier run left in it fails the check.

A fixture can also have an expected-report-rerun file. Its first lines, other
than comments and blank lines, are `<key>: <value>` settings, and the rest name
features as above. The task then runs the fixture's tests again, straight after
the first run, and checks the report with this script: the new run must replace
the first run's report, not add to it.

  tags: <tags>              a Swift package: `swift test` with CUCUMBER_TAGS set
                            to the tags. `swift test --filter` can't choose the
                            XCTest runner's scenarios, whose test classes exist
                            only while the tests run.
  only-testing: <target>    an Xcode project: `xcodebuild test` of the scheme
                            with -only-testing:<target>.

  python3 .github/scripts/fixture_report.py get <expected file> <key>

prints a setting. Both commands read only files in the working folder, the home
folder or a temporary folder, as the fixtures' files and reports are.

The expected-report file of a Swift package fixture whose test run ages the
report, by `ages-report: <suffix>`, also needs the file `<report><suffix>`.
The fixture's first runner writes that file as it exits, after it sets the
report's age to 2 hours, so that the next runner starts when the report is
stale. The next runner must still keep it: the features of both runners are
in the report. Only the standard library is used.
"""
import json
import os
import sys
import tempfile

SETTINGS = ("tags", "only-testing", "ages-report")


def confined(path):
    """The real path of a file in the working folder, the home folder or a temporary folder, else an error."""
    real = os.path.realpath(path)
    roots = [os.getcwd(), os.path.expanduser("~"), tempfile.gettempdir(), os.environ.get("RUNNER_TEMP", "")]
    for root in filter(None, roots):
        base = os.path.realpath(root)
        if os.path.commonpath([real, base]) == base:
            return real
    raise ValueError(f"{path} is not in the working folder, the home folder or a temporary folder")


def lines(path):
    with open(confined(path), encoding="utf-8") as file:
        stripped = (line.strip() for line in file)
        return [line for line in stripped if line and not line.startswith("#")]


def expectation(path):
    """The settings, as a dictionary, and the feature names an expected file gives."""
    names = lines(path)
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


def main(argv):
    try:
        return run(argv)
    except ValueError as error:
        print(f"error: {error}")
        return 1


def run(argv):
    if len(argv) == 4 and argv[1] == "get":
        settings, _ = expectation(argv[2])
        if argv[3] not in settings:
            print(f"error: {argv[2]}: has no `{argv[3]}:` setting")
            return 1
        print(settings[argv[3]])
        return 0
    if len(argv) != 4 or argv[1] != "check":
        print(__doc__)
        return 2
    settings, expected = expectation(argv[2])
    report_path = confined(argv[3])
    if "ages-report" in settings and not os.path.exists(report_path + settings["ages-report"]):
        print(f"error: {argv[2]}: the fixture didn't age the report: there is no {report_path + settings['ages-report']}")
        return 1
    try:
        with open(report_path, encoding="utf-8") as file:
            report = json.load(file)
    except (OSError, ValueError) as error:
        print(f"error: {argv[2]}: can't read the report {argv[3]}: {error}")
        return 1
    messages = problems(expected, report)
    for message in messages:
        print(f"error: {argv[2]}: {message}")
    if messages:
        return 1
    features = "feature" if len(expected) == 1 else "features"
    print(f"{argv[2]}: the report has the {len(expected)} {features} it lists, and no other.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
