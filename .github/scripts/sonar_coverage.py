#!/usr/bin/env python3
"""Convert test coverage into SonarQube's generic coverage format.

  sonar_coverage.py xcresult   read the Xcode result bundle fastlane writes
                               under fastlane/test_output, through `xcrun xccov`
  sonar_coverage.py lcov       read info.lcov, as `llvm-cov export -format=lcov`
                               writes it for Codecov

Run it from the repository root. It writes sq-generic.xml there, with only the
files under Sources/, and with their paths relative to the root, so the report
can be read by a job with its checkout somewhere else. The paths are fixed
rather than arguments, so nothing on the command line reaches a file or xccov.

The same file is used by CucumberSwift and CucumberSwiftExpressions; keep the
two copies identical.
"""
import argparse
import glob
import json
import os
import subprocess
import sys
import xml.etree.ElementTree as ET

RESULT_BUNDLES = os.path.join("fastlane", "test_output", "*.xcresult")
LCOV = "info.lcov"
OUTPUT = "sq-generic.xml"
SOURCES = "Sources"


def fail(message):
    print(f"::error::{message}")
    sys.exit(1)


def merge(coverage, path, line, covered):
    """Record one line, keeping it covered if any report says so."""
    lines = coverage.setdefault(path, {})
    lines[line] = lines.get(line, False) or covered


def from_xccov(report):
    """Coverage from `xccov view --archive --json`: path -> [line records]."""
    coverage = {}
    for path, lines in report.items():
        for record in lines:
            if record.get("isExecutable"):
                merge(coverage, path, record["line"], record.get("executionCount", 0) > 0)
    return coverage


def from_lcov(text):
    """Coverage from an lcov file's SF (source file) and DA (line) records."""
    coverage = {}
    path = None
    for raw in text.splitlines():
        line = raw.strip()
        if line.startswith("SF:"):
            path = line[3:]
        elif line.startswith("DA:") and path is not None:
            number, count = line[3:].split(",")[:2]
            merge(coverage, path, int(number), int(count) > 0)
        elif line == "end_of_record":
            path = None
    return coverage


def under(folder, path):
    return os.path.commonpath([folder, path]) == folder


def relative_to_root(coverage, root, include=()):
    """Keep files under root (and under an include, if any), keyed relative to root."""
    root = os.path.realpath(root)
    folders = [os.path.realpath(os.path.join(root, folder)) for folder in include] or [root]
    kept = {}
    for path, lines in coverage.items():
        full = os.path.realpath(path)
        if under(root, full) and any(under(folder, full) for folder in folders):
            kept[os.path.relpath(full, root)] = lines
    return kept


def to_xml(coverage):
    top = ET.Element("coverage", version="1")
    for path in sorted(coverage):
        node = ET.SubElement(top, "file", path=path)
        for number, covered in sorted(coverage[path].items()):
            ET.SubElement(node, "lineToCover", lineNumber=str(number),
                          covered="true" if covered else "false")
    return ET.tostring(top, encoding="unicode") + "\n"


def read_xcresult():
    bundles = sorted(glob.glob(RESULT_BUNDLES))
    if len(bundles) != 1:
        fail(f"expected one result bundle matching {RESULT_BUNDLES}, found {len(bundles)}")
    # An absolute path, so xccov can never read it as an option.
    bundle = os.path.abspath(bundles[0])
    result = subprocess.run(
        ["xcrun", "xccov", "view", "--archive", "--json", bundle],
        capture_output=True, text=True, check=False)
    if result.returncode != 0:
        fail(f"xccov could not read {bundles[0]}: {result.stderr.strip()}")
    return from_xccov(json.loads(result.stdout))


def read_lcov():
    if not os.path.isfile(LCOV):
        fail(f"{LCOV} not found")
    with open(LCOV, encoding="utf-8") as handle:
        return from_lcov(handle.read())


READERS = {"xcresult": read_xcresult, "lcov": read_lcov}


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("format", choices=sorted(READERS))
    args = parser.parse_args(argv)

    coverage = relative_to_root(READERS[args.format](), os.curdir, [SOURCES])
    if not coverage:
        fail(f"no covered files under {SOURCES}/")
    with open(OUTPUT, "w", encoding="utf-8") as handle:
        handle.write(to_xml(coverage))
    lines = sum(len(lines) for lines in coverage.values())
    print(f"Wrote coverage for {len(coverage)} files ({lines} lines) to {OUTPUT}")


if __name__ == "__main__":
    main()
