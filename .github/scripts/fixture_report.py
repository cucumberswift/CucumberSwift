#!/usr/bin/env python3
"""Check the Cucumber JSON report a fixture's test run wrote.

A test run writes one report, whichever runners its test targets use (#546).
So `mise run test-fixtures` gives a fixture that has an expected-report file a
report path of its own, runs its tests, and checks the report with this script:

  python3 .github/scripts/fixture_report.py check <expected file> <report>

Each line of the expected file, other than comments and blank lines, names a
feature the report must have, with at least one scenario. The report must have
no other feature, so a feature an earlier run left in it fails the check.

A Swift package fixture can also have an expected-report-rerun file. Its first
line, other than comments and blank lines, is `tags: <tags>`, and the rest name
features as above. The task runs `swift test` again with CUCUMBER_TAGS set to
the tags, straight after the first run, and checks the report with this script:
the new run must replace the first run's report, not add to it. Tags, because
`swift test --filter` can't choose the XCTest runner's scenarios, whose test
classes exist only while the tests run.

  python3 .github/scripts/fixture_report.py tags <expected file>

prints the tags. Only the standard library is used.
"""
import json
import sys

TAGS = "tags:"


def lines(path):
    with open(path, encoding="utf-8") as file:
        stripped = (line.strip() for line in file)
        return [line for line in stripped if line and not line.startswith("#")]


def expectation(path):
    """The tags, or None, and the feature names an expected file gives."""
    names = lines(path)
    tags = None
    if names and names[0].startswith(TAGS):
        tags = names.pop(0)[len(TAGS):].strip()
        if not tags:
            raise ValueError(f"{path}: `{TAGS}` gives no tags")
    if not names:
        raise ValueError(f"{path}: names no feature")
    return tags, names


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
    if len(argv) == 3 and argv[1] == "tags":
        tags, _ = expectation(argv[2])
        if tags is None:
            print(f"error: {argv[2]}: its first line isn't `{TAGS} <tags>`")
            return 1
        print(tags)
        return 0
    if len(argv) != 4 or argv[1] != "check":
        print(__doc__)
        return 2
    _, expected = expectation(argv[2])
    try:
        with open(argv[3], encoding="utf-8") as file:
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
