"""Checks the records a run of a parallel testing fixture wrote, for parallel-fixture.sh.

Each run of a scenario and each feature hook writes an empty file to the records folder
(Tests/ParallelFixtures/Support/ParallelFixtureSupport.swift), named

  <process>.<sequence>.<kind>.<feature>.<scenario>.<UUID>

where <kind> is scenario, before (BeforeFeature) or after (AfterFeature), <sequence> orders a
process's records, and <scenario> is - for a feature hook. Each worker is a process.

It fails unless:

- every scenario ran exactly once, and there were as many as expected;
- with the scenario unit, the scenarios ran in at least --min-workers workers;
- in each worker, each of a feature's scenarios came after that worker's BeforeFeature for it and
  before its AfterFeature;
- with the scenario unit, each worker that ran one of a feature's scenarios ran each of its hooks
  once, and no other worker ran them;
- with the feature unit, each feature's scenarios all ran in one worker, which ran each of its hooks
  once, and no other worker ran them.

- with --features, and every scenario run by one worker, the scenarios ran in the order of the
  feature files: the features sorted by path, then each feature's scenarios by line (#388).

  python3 .github/scripts/parallel_records.py <folder> --unit scenario|feature \\
      --expected-scenarios 10 [--min-workers 2] [--features <folder of .feature files>]

Only the standard library is used.
"""
import argparse
import os
import sys
from collections import Counter, defaultdict
from typing import List, NamedTuple, Optional, Tuple

KINDS = ("scenario", "before", "after")


class Record(NamedTuple):
    process: str
    sequence: int
    kind: str
    feature: str
    scenario: str


def parse(name: str) -> Optional[Record]:
    """The record a file name stands for, or None when it isn't one."""
    parts = name.split(".")
    if len(parts) != 6 or not parts[0].isdigit() or not parts[1].isdigit() or parts[2] not in KINDS:
        return None
    return Record(parts[0], int(parts[1]), parts[2], parts[3], parts[4])


def line_of(scenario: str) -> int:
    """The line in its feature file of a record's scenario, written line-<n>-<title>."""
    parts = scenario.split("-")
    return int(parts[1]) if len(parts) > 1 and parts[0] == "line" and parts[1].isdigit() else 0


def record_part(text: str) -> str:
    """A title as it appears in a record's file name: only letters, numbers and dashes."""
    return "".join(c if c.isalnum() else "-" for c in text)


def feature_titles(folder: str) -> List[str]:
    """The titles of the feature files in the folder, as in a record's name, in the order of their paths."""
    titles = []
    for name in sorted(os.listdir(folder)):
        if not name.endswith(".feature"):
            continue
        with open(os.path.join(folder, name), encoding="utf-8") as handle:
            for line in handle:
                if line.strip().startswith("Feature:"):
                    titles.append(record_part(line.split(":", 1)[1].strip()))
                    break
    return titles


def check(names: List[str], unit: str, expected_scenarios: int, min_workers: int,
          feature_order: Optional[List[str]] = None) -> Tuple[List[str], List[str]]:
    """What to print, and the errors, for the records' file names.

    With feature_order, the titles of the features in the order of their files, and every scenario run by
    one worker, it also fails unless the scenarios ran in the order of the feature files."""
    lines, errors = [], []
    records = []
    for name in names:
        record = parse(name)
        if record is None:
            errors.append(f"Not a record: {name}")
        else:
            records.append(record)

    scenario_runs = Counter((r.feature, r.scenario) for r in records if r.kind == "scenario")
    workers = {r.process for r in records if r.kind == "scenario"}
    lines.append(f"Scenario records: {sum(scenario_runs.values())} for {len(scenario_runs)} scenarios, "
                 f"from {len(workers)} workers ({expected_scenarios} scenarios expected)")
    for (feature, scenario), count in sorted(scenario_runs.items()):
        if count > 1:
            errors.append(f"Ran {count} times: {feature} {scenario}")
    if len(scenario_runs) != expected_scenarios:
        errors.append(f"{len(scenario_runs)} of {expected_scenarios} scenarios ran. If you changed the fixtures' "
                      "features, update EXPECTED_SCENARIOS in .github/scripts/parallel-fixture.sh.")
    if unit == "scenario" and len(workers) < min_workers:
        errors.append(f"The scenarios ran in {len(workers)} workers, and plain XCTest classes in at least "
                      f"{min_workers}, so they did not run in parallel.")

    if feature_order is not None:
        if len(workers) == 1:
            ran = [(r.feature, r.scenario) for r in sorted(records, key=lambda r: (r.process, r.sequence))
                   if r.kind == "scenario"]
            rank = {title: index for index, title in enumerate(feature_order)}
            expected = sorted(ran, key=lambda run: (rank.get(run[0], len(rank)), line_of(run[1])))
            if ran == expected:
                lines.append("The scenarios ran in one worker, in the order of the feature files")
            else:
                errors.append("The scenarios ran in one worker, but not in the order of the feature files. "
                              f"Ran: {', '.join(f'{f} {s}' for f, s in ran)}. "
                              f"Expected: {', '.join(f'{f} {s}' for f, s in expected)}.")
        else:
            lines.append(f"Not checking the order of the scenarios: they ran in {len(workers)} workers")

    # Each feature's records, by worker, in the order the worker wrote them.
    by_feature = defaultdict(lambda: defaultdict(list))
    for record in sorted(records, key=lambda r: (r.process, r.sequence)):
        by_feature[record.feature][record.process].append(record)

    hook_counts = []
    for feature, by_worker in sorted(by_feature.items()):
        running = sorted(w for w, rs in by_worker.items() if any(r.kind == "scenario" for r in rs))
        hook_counts.append(f"{feature}: " + ", ".join(
            f"worker {w} {sum(r.kind == 'before' for r in rs)}/{sum(r.kind == 'scenario' for r in rs)}/"
            f"{sum(r.kind == 'after' for r in rs)}" for w, rs in sorted(by_worker.items())))
        if unit == "feature" and len(running) > 1:
            errors.append(f"With whole features, '{feature}' ran its scenarios in {len(running)} workers, not one.")
        for worker, worker_records in sorted(by_worker.items()):
            kinds = [r.kind for r in worker_records]
            runs_scenarios = "scenario" in kinds
            before, after = kinds.count("before"), kinds.count("after")
            if not runs_scenarios:
                if before or after:
                    errors.append(f"Worker {worker} ran no scenario of '{feature}', but ran BeforeFeature "
                                  f"{before} times and AfterFeature {after} times for it.")
                continue
            if before != 1 or after != 1:
                errors.append(f"Worker {worker} ran scenarios of '{feature}', and BeforeFeature {before} times "
                              f"and AfterFeature {after} times for it, not once each.")
                continue
            if kinds[0] != "before" or kinds[-1] != "after":
                errors.append(f"In worker {worker}, the records of '{feature}' are in the order "
                              f"{', '.join(kinds)}: BeforeFeature should come first and AfterFeature last.")
            lines_run = [line_of(r.scenario) for r in worker_records if r.kind == "scenario"]
            if unit == "feature" and lines_run != sorted(lines_run):
                errors.append(f"With whole features, worker {worker} ran the scenarios of '{feature}' at lines "
                              f"{', '.join(map(str, lines_run))}, not in the feature file's order.")
    lines.append("Feature hooks, as BeforeFeature/scenarios/AfterFeature in each worker:")
    lines.extend(f"  {line}" for line in hook_counts)
    return lines, errors


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("folder")
    parser.add_argument("--unit", choices=("scenario", "feature"), required=True)
    parser.add_argument("--expected-scenarios", type=int, required=True)
    parser.add_argument("--min-workers", type=int, default=1)
    parser.add_argument("--features", help="the folder of the feature files, to check the order of the scenarios")
    args = parser.parse_args(argv)
    names = sorted(os.listdir(args.folder)) if os.path.isdir(args.folder) else []
    feature_order = feature_titles(args.features) if args.features else None
    lines, errors = check(names, args.unit, args.expected_scenarios, args.min_workers, feature_order)
    for line in lines:
        print(line)
    for error in errors:
        print(f"::error::{error}", file=sys.stderr)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
