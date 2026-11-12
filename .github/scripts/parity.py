#!/usr/bin/env python3
"""Normalize a parity run's result, and compare it with the golden result.

The parity suite in Fixtures/Parity runs one set of feature files and one
step-definition file with every build tool, runner, run mode and platform
(#561). Each run writes one normalized result, and every result must equal
Fixtures/Parity/golden.json, apart from the differences that
Fixtures/Parity/known-differences.json allows. `mise run test-parity` runs a
combination and calls this script:

  parity.py normalize --combination <c> --log <output> --report <json>
                      --trace <folder> --status <exit status> --out <file>
                      [--xcresult-summary <json>]
  parity.py compare --result <file> [--golden <file>] [--known <file>]
  parity.py golden --result <file> [--golden <file>]
  parity.py known --result <file> [--golden <file>]

A combination names what ran, as build tool/runner/mode/platform, such as
swiftpm/xctest/serial/macOS. The runner is xctest or swift-testing, and the
mode serial or parallel.

`normalize` reads what the run left. With --xcresult-summary, the output of
`xcrun xcresulttool get test-results summary`, the test count and the failed
scenarios come from the result bundle, which has them when Xcode runs tests in
parallel workers and its log doesn't.: the test output, the Cucumber JSON
report, the trace files the step definitions write (see ParitySteps.swift)
and the exit status. It keeps what a user sees and drops what changes from
run to run or from Mac to Mac:

  exit          passed or failed;
  tests         how many tests the runner ran, as fixture_tests.py counts
                them. Each runner counts differently, so the golden result
                has a count for each runner;
  features      from the report: each feature's tags, and each scenario's
                tags and steps, with each step's result and the first line
                of its error, without paths, durations or ids;
  hooks         how many times each feature's hooks ran;
  trace         each scenario's steps and hooks, in the order they ran;
  failed        the scenarios the runner reports as failed, by title;
  messages      the lines CucumberSwift prints, such as the coverage scores
                and the warnings on feature files, sorted, without paths.

Scenarios that run in parallel finish in any order, so features and
scenarios are keyed by name, and the trace by scenario.

Two things can't be compared when Xcode runs tests in parallel workers, and
the result leaves them out, here and not in known-differences.json, because
they aren't behaviour a user can change:

  - Each worker process runs a feature's hooks once, so a hook that ran in
    several workers counts as having run once (parallel-fixture.sh checks
    the counts per worker).
  - xcodebuild's log doesn't hold the workers' output, so there are no
    messages to compare, and the result has none; compare skips them.

`compare` fails when the result differs from the golden one, printing a
unified diff. The golden result records the intended behaviour. A known
difference is an entry in known-differences.json, for a combination whose
behaviour differs until an issue lands, or for a limit a maintainer accepted:

  {"kind": "pending",
   "combination": "*/swift-testing/parallel/*",
   "changes": [{"path": ["messages"], "value": [...]}],
   "behaviour": "What differs, as a user sees it",
   "issues": [123],
   "approved": "The maintainer who approved it, and when"}

The `kind` is `pending`, behaviour that differs until the open issues in `issues` fix it, or `accepted`, a limit
a maintainer approved, with the maintainer and the date in `approved`. parity_known.py checks the kinds, fails
the Parity tests job when a pending entry cites a closed issue, and fails a release while a pending entry cites
an issue that is open in the release's milestone.

The entry applies to every combination that matches its pattern, or any of
its patterns if `combination` is a list (fnmatch). Each
change replaces the golden value at `path` (keys into the result) with
`value`, or removes it when `value` is absent. `compare` fails on an entry
without a behaviour, an issue, an approval or a change (or `ignore`), and on a change that
applies but no longer differs from the golden result, so that a fixed
difference leaves the file.

A parallel run can't measure coverage per scenario, so the golden result has
a `parallel` object: the values that replace the golden ones in a parallel run
(the coverage-off message, and each runner's test count without the coverage
tests). `golden` run on a parallel result writes only those two values there.

An entry may instead (or also) list `ignore`: paths the comparison leaves out of both results. Use it only for
behaviour that varies from run to run, such as steps that lose their state in
a different order, which no value can pin.

`known` prints the changes that make the golden result equal a result, as the
JSON to put in an entry's `changes`, for the combination the result names.

`golden` writes the result as the golden one, for a deliberate change to the
suite, keeping the other runner's test count. With --tests-only it writes only
the runner's test count. Check the diff before committing it.

Only the standard library is used.
"""
import argparse
import copy
import difflib
import fnmatch
import json
import os
import pathlib
import re
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import parity_known  # noqa: E402
from fixture_tests import count_tests  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
GOLDEN = os.path.join(ROOT, "Fixtures", "Parity", "golden.json")
KNOWN = os.path.join(ROOT, "Fixtures", "Parity", "known-differences.json")

TOOLS = ("swiftpm", "xcode")
RUNNERS = {"xctest": "XCTest", "swift-testing": "Swift Testing"}
MODES = ("serial", "parallel")
PLATFORMS = ("macOS", "Catalyst", "iOS", "tvOS", "watchOS")

# The tag on a scenario whose failure message is its assertion API's own.
ASSERTION_TEXT = "assertion-text"
# A path, as tools print one: absolute, or a file:// URL.
PATH = re.compile(r"(?:file://)?(?:/[^/\s:'\"()]+)*/")
# CucumberSwift's lines: its coverage report and its notes.
CUCUMBER_LINE = re.compile(r"^\s*(CucumberSwift( coverage)?:(?!\s*/).*)$")
# A warning on a feature file, as the coverage scores give one.
FEATURE_WARNING = re.compile(r"([^/\s:]+\.feature):(\d+)(?::\d+)?: (warning): (.*)$")
TRACE_HEADER = re.compile(r"^(scenario|feature): (.*)$")
# A failed scenario: the XCTest runner's suite for it, named "Feature › Scenario", or the Swift Testing runner's test.
XCTEST_FAILED = re.compile(r"^Test Suite '(?:.+ › )?(.+)' failed at ")
SWIFT_TESTING_FAILED = re.compile(r'^\S+ Test "(.+)" (?:with \d+ test cases? )?failed after ')
# What differs from run to run in CucumberSwift's lines: times and the coverage run's folder.
# The test target's folder and line in an error that quotes where it was recorded.
SOURCE_LOCATION = re.compile(r"sourceLocation: [^)\s]*ParitySteps\.swift:\d+:\d+")
SECONDS = re.compile(r"\b\d+(\.\d+)? s\b")
RUN_ID = re.compile(r"\brun-[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}\b")


class ParityError(Exception):
    """A combination, a result or a known-differences file that isn't valid."""


def parse_combination(combination):
    parts = combination.split("/")
    if len(parts) != 4 or not all(parts):
        raise ParityError(f"a combination is tool/runner/mode/platform, not {combination!r}")
    if parts[0] not in TOOLS:
        raise ParityError(f"the build tool must be one of {', '.join(TOOLS)}, not {parts[0]!r}")
    if parts[1] not in RUNNERS:
        raise ParityError(f"the runner must be one of {', '.join(RUNNERS)}, not {parts[1]!r}")
    if parts[2] not in MODES:
        raise ParityError(f"the mode must be one of {', '.join(MODES)}, not {parts[2]!r}")
    if parts[3] not in PLATFORMS:
        raise ParityError(f"the platform must be one of {', '.join(PLATFORMS)}, not {parts[3]!r}")
    return parts


def strip_paths(text):
    """`text` with every path cut down to its last component."""
    return PATH.sub("", text)


def strip_noise(text):
    """`text` without paths, times or run folders."""
    text = SOURCE_LOCATION.sub("sourceLocation: <step definition>", text)
    return RUN_ID.sub("run-<id>", SECONDS.sub("<n> s", strip_paths(text)))


def first_line(text):
    return strip_paths(text.strip().splitlines()[0].strip()) if text.strip() else ""


def normalize_step(step, tags):
    """One step as `line keyword name: status (first line of the error)`. An assertion's message is the assertion
    API's own, such as XCTAssertEqual's or #expect's, so a scenario tagged @assertion-text compares only that its
    step failed."""
    result = step.get("result", {})
    text = f"{step.get('line')} {step.get('keyword', '').strip()} {step.get('name')}: {result.get('status')}"
    error = "" if ASSERTION_TEXT in tags else strip_noise(first_line(result.get("error_message", "")))
    return f"{text} ({error})" if error else text


def normalize_scenario(element):
    tags = [tag.get("name") for tag in element.get("tags", [])]
    return {
        "keyword": element.get("keyword"),
        "tags": tags,
        "steps": [normalize_step(step, tags) for step in element.get("steps", [])],
    }


def normalize_report(report):
    """{feature name: {tags, scenarios: {name (line N): {tags, steps}}}} from a Cucumber JSON report."""
    features = {}
    for feature in report:
        scenarios = {}
        for element in feature.get("elements", []):
            key = f"{element.get('name')} (line {element.get('line')})"
            scenarios.setdefault(key, []).append(normalize_scenario(element))
        features[feature.get("name")] = {
            "tags": [tag.get("name") for tag in feature.get("tags", [])],
            "file": os.path.basename(feature.get("uri", "")),
            "scenarios": scenarios,
        }
    return features


def trace_files(folder):
    """The lines of each trace file in `folder`, in the order of the file names. An empty file is left out."""
    if not folder or not os.path.isdir(folder):
        return
    for name in sorted(os.listdir(folder)):
        if name.endswith(".trace"):
            with open(os.path.join(folder, name), encoding="utf-8", errors="replace") as f:
                lines = f.read().splitlines()
            if lines:
                yield lines


def read_trace(folder):
    """(hooks, trace) from the trace files the step definitions wrote."""
    hooks, trace = {}, {}
    for lines in trace_files(folder):
        match = TRACE_HEADER.match(lines[0])
        if match and match.group(1) == "feature":
            counts = hooks.setdefault(match.group(2), {})
            for event in lines[1:]:
                counts[event] = counts.get(event, 0) + 1
        else:
            trace.setdefault(match.group(2) if match else lines[0], []).append(lines[1:])
    for runs in trace.values():
        runs.sort()
    return hooks, trace


def read_messages(output):
    """The sorted, distinct lines CucumberSwift printed, without paths."""
    messages = set()
    for line in output.splitlines():
        match = CUCUMBER_LINE.match(line)
        if match:
            messages.add(strip_noise(match.group(1)).rstrip())
            continue
        match = FEATURE_WARNING.search(line)
        if match:
            messages.add(f"{match.group(1)}:{match.group(2)}: {match.group(3)}: {strip_noise(match.group(4)).rstrip()}")
    return sorted(messages)


def read_failed(output):
    """The sorted titles of the scenarios the runner reported as failed."""
    failed = set()
    for line in output.splitlines():
        match = XCTEST_FAILED.match(line)
        if match and " › " in line:
            failed.add(match.group(1))
            continue
        match = SWIFT_TESTING_FAILED.match(line)
        if match:
            failed.add(match.group(1))
    return sorted(failed)


def failed_from_summary(summary):
    """The sorted scenario titles of the failures in an xcresult summary. The XCTest runner's failed test is
    a step, identified as `Feature › Scenario/1 › Step`, with `F01 S02 › ` before it when Xcode makes a test
    class for each scenario. The Swift Testing runner's is the scenario, named by its testName."""
    failed = set()
    for failure in summary.get("testFailures", []):
        parts = re.sub(r"^F\d+ S\d+ › ", "", failure.get("testIdentifierString", "")).split(" › ")
        if len(parts) >= 3:
            failed.add(parts[1].rsplit("/", 1)[0])
        else:
            failed.add(failure.get("testName", ""))
    return sorted(failed)


def normalize(combination, output, report, trace_folder, status, summary=None):
    _, runner, mode, _ = parse_combination(combination)
    framework = RUNNERS[runner]
    hooks, trace = read_trace(trace_folder)
    # A run that has an xcresult summary is xcodebuild's, whose parallel workers' output is not in its log.
    workers = summary is not None and mode == "parallel"
    if workers:
        hooks = {feature: dict.fromkeys(counts, 1) for feature, counts in hooks.items()}
    tests = summary["totalTestCount"] if summary else count_tests(output)[framework]
    result = {
        "exit": "passed" if status == 0 else "failed",
        "tests": {framework: tests},
        "features": normalize_report(report),
        "hooks": hooks,
        "trace": trace,
        "failed": failed_from_summary(summary) if summary else read_failed(output),
        "messages": read_messages(output),
    }
    if workers:
        del result["messages"]
    return result


def read_json(path, what):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError as error:
        raise ParityError(f"no {what} at {path}") from error
    except json.JSONDecodeError as error:
        raise ParityError(f"the {what} at {path} isn't valid JSON: {error}") from error


def dump(value):
    return json.dumps(value, indent=2, sort_keys=True, ensure_ascii=False) + "\n"


def diff_changes(expected, actual, path=()):
    """The changes that turn `expected` into `actual`: the paths where they differ, as {path, value} (a missing key
    in `actual` has no value). It descends through objects and replaces lists and scalars whole."""
    changes = []
    if isinstance(expected, dict) and isinstance(actual, dict):
        for key in sorted(set(expected) | set(actual)):
            if key not in actual:
                changes.append({"path": list(path) + [key]})
            elif key not in expected:
                changes.append({"path": list(path) + [key], "value": actual[key]})
            else:
                changes += diff_changes(expected[key], actual[key], path + (key,))
    elif expected != actual:
        changes.append({"path": list(path), "value": actual})
    return changes


def get_path(value, path):
    for key in path:
        value = value.get(key) if isinstance(value, dict) else None
    return value


def check_entry(index, entry):
    """Raises ParityError unless the known difference has every field, and its issues are a list."""
    for field in ("combination", "behaviour", "issues", "approved"):
        if not entry.get(field):
            raise ParityError(f"known difference {index} has no {field}")
    if not entry.get("changes") and not entry.get("ignore"):
        raise ParityError(f"known difference {index} has no changes or ignore")
    if not isinstance(entry["issues"], list):
        raise ParityError(f"known difference {index}'s issues must be a list of issue numbers")
    if entry.get("kind") not in parity_known.KINDS:
        raise ParityError(f"known difference {index} has kind {entry.get('kind')!r}, not one of "
                          f"{', '.join(parity_known.KINDS)}")


def applies_to(entry, combination):
    patterns = entry["combination"] if isinstance(entry["combination"], list) else [entry["combination"]]
    return any(fnmatch.fnmatchcase(combination, pattern) for pattern in patterns)


def apply_change(expected, index, change):
    """Applies one change to `expected` and returns the value it replaced."""
    path = change.get("path")
    if not isinstance(path, list) or not path:
        raise ParityError(f"known difference {index} has a change whose path isn't a list of keys")
    parent = get_path(expected, path[:-1])
    if not isinstance(parent, dict):
        raise ParityError(f"known difference {index}'s path {path} isn't in the golden result")
    before = copy.deepcopy(parent.get(path[-1]))
    if "value" in change:
        parent[path[-1]] = change["value"]
    else:
        parent.pop(path[-1], None)
    return before


def golden_for(golden, runner, mode):
    """The golden result for a runner and a run mode: the parallel values replace the golden ones in a parallel run,
    and the result has only the runner's test count."""
    expected = copy.deepcopy(golden)
    overlay = expected.pop("parallel", {})
    if mode == "parallel":
        expected.update(copy.deepcopy(overlay))
    framework = RUNNERS[runner]
    if framework not in expected.get("tests", {}):
        raise ParityError(f"the golden result has no {framework} test count")
    expected["tests"] = {framework: expected["tests"][framework]}
    return expected


def expected_for(golden, combination, known):
    """The golden result as `combination` should give it: the runner's test count, and the known differences
    that apply. Returns it with the applied changes as (entry number, entry, change, golden value). Raises
    ParityError on a malformed entry."""
    _, runner, mode, _ = parse_combination(combination)
    expected = golden_for(golden, runner, mode)
    applied = []
    for index, entry in enumerate(known, start=1):
        check_entry(index, entry)
        if applies_to(entry, combination):
            for key in entry.get("ignore", []):
                expected.pop(key, None)
                expected.setdefault("_ignored", []).append(key)
            for change in entry.get("changes") or []:
                applied.append((index, entry, change, apply_change(expected, index, change)))
    return expected, applied


def compare(result, golden, known, combination):
    """The errors, an empty list when the result matches."""
    expected, applied = expected_for(golden, combination, known)
    if "messages" not in result:
        expected.pop("messages", None)
    result = {key: value for key, value in result.items() if key not in expected.get("_ignored", [])}
    expected.pop("_ignored", None)
    errors = []
    for index, entry, change, before in applied:
        if get_path(result, change["path"]) == before:
            errors.append(f"error: known difference {index} ({entry['behaviour']}) changes {'/'.join(change['path'])} "
                          f"for {combination}, but the result no longer differs there. Remove the change from "
                          f"known-differences.json.")
    if result != expected:
        diff = difflib.unified_diff(dump(expected).splitlines(), dump(result).splitlines(),
                                    "golden.json (with known differences)", combination, lineterm="")
        errors.append(f"error: {combination} differs from the golden result:\n" + "\n".join(diff))
    return errors


def allowed_roots():
    """The folders a path argument may be in: the checkout, the working folder, and the temporary folders."""
    roots = [ROOT, os.getcwd(), tempfile.gettempdir(), os.environ.get("RUNNER_TEMP"), os.environ.get("PARITY_OUTPUT")]
    return [pathlib.Path(root).resolve() for root in roots if root]


def contained(path):
    """`path` as an absolute path, if it is inside one of the allowed folders. Raises ParityError otherwise."""
    resolved = pathlib.Path(path).resolve()
    if not any(resolved.is_relative_to(root) for root in allowed_roots()):
        raise ParityError(f"{path} isn't in the checkout, the working folder or a temporary folder")
    return str(resolved)


def command_normalize(args):
    with open(contained(args.log), encoding="utf-8", errors="replace") as f:
        output = f.read()
    report_path = contained(args.report)
    report = read_json(report_path, "Cucumber JSON report") if os.path.exists(report_path) else []
    summary = read_json(contained(args.xcresult_summary), "xcresult summary") if args.xcresult_summary else None
    result = normalize(args.combination, output, report, contained(args.trace), args.status, summary)
    result["combination"] = args.combination
    with open(contained(args.out), "w", encoding="utf-8") as f:
        f.write(dump(result))


def command_golden(args, result, combination):
    """Writes the result into the golden file: a serial result replaces the golden values, and a parallel one only
    the `parallel` values. The other runner's test count stays."""
    path = contained(args.golden)
    golden = read_json(path, "golden result") if os.path.exists(path) else {"tests": {}}
    if combination.split("/")[2] == "parallel":
        overlay = golden.setdefault("parallel", {"tests": dict(golden.get("tests", {}))})
        overlay["tests"].update(result["tests"])
        if "messages" in result and not args.tests_only:
            overlay["messages"] = result["messages"]
        result = golden
    else:
        tests = {**golden.get("tests", {}), **result["tests"]}
        if args.tests_only:
            result = golden
        else:
            result["parallel"] = golden.get("parallel", {})
        result["tests"] = tests
    with open(path, "w", encoding="utf-8") as f:
        f.write(dump(result))
    print(f"Wrote {combination}'s result to {path}.")


def command_known(golden, result, combination):
    expected, _ = expected_for(golden, combination, [])
    if "messages" not in result:
        expected.pop("messages", None)
    print(json.dumps(diff_changes(expected, result), indent=2, sort_keys=True, ensure_ascii=False))


def parse_arguments(argv):
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    commands = parser.add_subparsers(dest="command", required=True)
    n = commands.add_parser("normalize")
    for name in ("combination", "log", "report", "trace", "out"):
        n.add_argument(f"--{name}", required=True)
    n.add_argument("--status", required=True, type=int)
    n.add_argument("--xcresult-summary")
    for name in ("compare", "golden", "known"):
        c = commands.add_parser(name)
        c.add_argument("--result", required=True)
        c.add_argument("--golden", default=GOLDEN)
        if name == "compare":
            c.add_argument("--known", default=KNOWN)
        if name == "golden":
            c.add_argument("--tests-only", action="store_true")
    return parser.parse_args(argv[1:])


def run(args):
    """Runs the command and returns the errors it found."""
    if args.command == "normalize":
        command_normalize(args)
        return []
    result = read_json(contained(args.result), "result")
    combination = result.pop("combination", None)
    if not combination:
        raise ParityError(f"{args.result} names no combination")
    if args.command == "golden":
        command_golden(args, result, combination)
        return []
    golden = read_json(contained(args.golden), "golden result")
    if args.command == "known":
        command_known(golden, result, combination)
        return []
    known_path = contained(args.known)
    known = read_json(known_path, "known differences") if os.path.exists(known_path) else []
    errors = compare(result, golden, known, combination)
    if not errors:
        print(f"{combination} matches the golden result.")
    return errors


def main(argv):
    args = parse_arguments(argv)
    try:
        errors = run(args)
    except ParityError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    for error in errors:
        print(error, file=sys.stderr)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
