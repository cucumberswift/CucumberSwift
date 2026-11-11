#!/usr/bin/env python3
"""Check a mutation testing run's report against the mutants a fixture expects.

  python3 .github/scripts/mutation_fixture.py <fixture folder> <report folder> [<build log>]

The fixture's expected-mutants file lists every mutant the run must find and
what must happen to it, one per line, other than comments and blank lines:

  Sources/Voting.swift:11 RelationalOperator < Killed

That is the file and line, the mutator's name, the replacement and the status
that mutation-report.json (the Stryker mutation report) gives the mutant:
Killed, Survived, Timeout or CompileError. The check fails, naming the mutant,
when a listed mutant is missing or has another status, and when the run found
a mutant the file does not list. It also fails when the file lists nothing or
has a line it cannot read, so a run that found no mutant can't pass.

With a build log, the run is one that Xcode's Run Script build phase made with `--format xcode`. The check then also
fails when the log has no warning at a surviving mutant's line, such as

  /path/Sources/Voting.swift:11:13: warning: No test failed after changing >= to > at Voting.swift:11. Add a scenario ...

and when it has one for a mutant that was killed.

The log also shows how many scenarios each tested mutant ran, as the run prints them:

  3/6 Voting.swift: >= to <: Killed (0.4 s, 2 of 14 scenarios)

The check fails unless every mutant that was tested has such a line, and each runs at least one scenario and at most
all of them, and at least one runs fewer than all of them, so a run that ran every scenario for every mutant can't pass.
Where the reports folder has the Cucumber report that the mutant's run wrote (cucumber-mutant-3.json), the report must
hold no more scenarios than that. It can hold fewer: a package with an XCTest and a Swift Testing target has both
runners write one report, and the one that finishes last replaces the other's.

Only the standard library is used.
"""
import json
import os
import re
import sys
import tempfile

STATUSES = ("Killed", "Survived", "Timeout", "CompileError")
LINE = re.compile(r"^(\S+):(\d+) (\w+) (\S+) (" + "|".join(STATUSES) + r")$")


class MutantsError(Exception):
    """An expected-mutants file or a report that cannot be read."""


def read_expected(path):
    """Return {(file, line, mutator, replacement): status} from expected-mutants."""
    if not os.path.isfile(path):
        raise MutantsError("has no expected-mutants file")
    expected = {}
    with open(path, encoding="utf-8") as f:
        for number, line in enumerate(f, start=1):
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            match = LINE.match(line)
            if not match:
                raise MutantsError(
                    f"expected-mutants line {number} isn't `<file>:<line> "
                    f"<mutator> <replacement> <status>`: {line}")
            key = (match.group(1), int(match.group(2)), match.group(3), match.group(4))
            if key in expected:
                raise MutantsError(f"expected-mutants lists a mutant twice: {line}")
            expected[key] = match.group(5)
    if not expected:
        raise MutantsError("expected-mutants lists no mutants")
    return expected


def read_report(path):
    """Return {(file, line, mutator, replacement): status} from a Stryker report."""
    try:
        with open(path, encoding="utf-8") as f:
            report = json.load(f)
        found = {}
        for name, file in report["files"].items():
            for mutant in file["mutants"]:
                key = (name, mutant["location"]["start"]["line"], mutant["mutatorName"], mutant["replacement"])
                # A second entry would replace the first: the run would pass with a mutant more than it lists.
                if key in found:
                    raise MutantsError(f"has a mutation-report.json that lists a mutant twice: {describe(key)}")
                found[key] = mutant["status"]
        return found
    except OSError as error:
        raise MutantsError(f"has no readable mutation-report.json: {error}")
    except (ValueError, KeyError, TypeError) as error:
        raise MutantsError(f"has a mutation-report.json that isn't a mutation report: {error!r}")


def describe(key):
    file, line, mutator, replacement = key
    return f"{file}:{line} {mutator} {replacement}"


def check(name, expected, found):
    """Return the errors for a run's mutants against the expected ones."""
    errors = []
    for key, status in expected.items():
        if key not in found:
            errors.append(f"error: {name}: the run found no mutant {describe(key)}, which expected-mutants lists as {status}")
        elif found[key] != status:
            errors.append(f"error: {name}: {describe(key)} is {found[key]}, but expected-mutants lists it as {status}")
    for key, status in found.items():
        if key not in expected:
            errors.append(f"error: {name}: the run found {describe(key)}, which is {status} and which expected-mutants doesn't list")
    return errors


def safe_path(path):
    """Return `path` with its links resolved, when it is in the working folder or a temporary folder.

    The command line names the fixture, the reports and the log, and the script reads files there, so it refuses a path
    that points anywhere else: the checkout, and the folders that CI and `mktemp` make for a run, hold all of them.
    """
    real = os.path.realpath(path)
    roots = [os.getcwd(), tempfile.gettempdir(), os.environ.get("RUNNER_TEMP", "")]
    for root in (os.path.realpath(root) for root in roots if root):
        if real == root or real.startswith(root + os.sep):
            return real
    raise MutantsError(f"{path} isn't in the working folder or a temporary folder")


def survivor_warning(key):
    """The pattern of the warning `--format xcode` prints for the mutant at `key`."""
    file, line, _mutator, replacement = key
    name = re.escape(os.path.basename(file))
    return re.compile(
        rf"{name}:{line}:\d+: warning: No test failed after changing \S+ to {re.escape(replacement)} at {name}:{line}\.")


def check_log(name, expected, log):
    """Return the errors for a build log's warnings against the mutants' statuses."""
    errors = []
    for key, status in expected.items():
        warned = survivor_warning(key).search(log) is not None
        if status == "Survived" and not warned:
            errors.append(f"error: {name}: the build log has no warning for {describe(key)}, which survived")
        elif status != "Survived" and warned:
            errors.append(f"error: {name}: the build log has a warning for {describe(key)}, which expected-mutants lists as {status}")
    return errors


TESTED = ("Killed", "Survived", "Timeout")
SCENARIO_COUNT = re.compile(r"^\s*(\d+)/(\d+) .*: (" + "|".join(TESTED) + r") \([\d.]+ s, (\d+) of (\d+) scenarios?\)\s*$")


def scenarios_in_report(path):
    """How many scenarios a Cucumber JSON report holds, or None when there is no report there."""
    try:
        with open(path, encoding="utf-8") as f:
            features = json.load(f)
        return sum(1 for feature in features for element in feature.get("elements", []) if element.get("type") == "scenario")
    except OSError:
        return None
    except (ValueError, AttributeError, TypeError):
        raise MutantsError(f"{path} isn't a Cucumber JSON report") from None


def check_scenarios(name, expected, log, reports):
    """Return the errors for the scenario counts in a log: every tested mutant ran some of the scenarios, not all of them."""
    counts = {}
    for line in log.splitlines():
        found = SCENARIO_COUNT.match(line)
        if found:
            counts[int(found.group(1))] = (found.group(3), int(found.group(4)), int(found.group(5)))
    tested = sum(1 for status in expected.values() if status in TESTED)
    if len(counts) != tested:
        return [f"error: {name}: the log shows the number of scenarios run for {len(counts)} mutants, and {tested} were tested"]
    errors = []
    for number, (_status, ran, every) in sorted(counts.items()):
        if not 1 <= ran <= every:
            errors.append(f"error: {name}: mutant {number} ran {ran} of {every} scenarios, which a run of covering scenarios can't")
        try:
            held = scenarios_in_report(os.path.join(reports, f"cucumber-mutant-{number}.json"))
        except MutantsError as error:
            errors.append(f"error: {name}: {error}")
            continue
        # Not `!=`, until the report overwrite is fixed in main (#546): a package with an XCTest and a Swift Testing
        # target has both runners write one report, and the last replaces the other's, so the report can hold fewer
        # scenarios than ran. Then it must equal the log's count.
        if held is not None and held > ran:
            errors.append(f"error: {name}: the log says mutant {number} ran {ran} scenarios, and its Cucumber report holds {held}")
    if all(ran == every for (_status, ran, every) in counts.values()):
        errors.append(f"error: {name}: every mutant ran every scenario: the run didn't select the scenarios that cover them")
    return errors


def main(argv):
    if len(argv) not in (3, 4):
        print("usage: mutation_fixture.py <fixture folder> <report folder> [<build log>]", file=sys.stderr)
        return 2
    name = os.path.basename(os.path.normpath(argv[1]))
    try:
        fixture, reports = safe_path(argv[1]), safe_path(argv[2])
        expected = read_expected(os.path.join(fixture, "expected-mutants"))
        found = read_report(os.path.join(reports, "mutation-report.json"))
    except MutantsError as error:
        print(f"error: {name}: {error}", file=sys.stderr)
        return 1
    errors = check(name, expected, found)
    if len(argv) == 4:
        try:
            with open(safe_path(argv[3]), encoding="utf-8", errors="replace") as f:
                log = f.read()
            errors += check_log(name, expected, log)
            errors += check_scenarios(name, expected, log, reports)
        except (OSError, MutantsError) as error:
            errors.append(f"error: {name}: can't read the build log: {error}")
    for error in errors:
        print(error, file=sys.stderr)
    if errors:
        return 1
    print(f"{name}: all {len(expected)} mutants are as expected-mutants lists them.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
