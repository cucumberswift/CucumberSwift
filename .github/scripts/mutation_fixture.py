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
                errors += check_log(name, expected, f.read())
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
