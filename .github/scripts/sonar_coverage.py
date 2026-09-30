#!/usr/bin/env python3
"""Convert test coverage into SonarQube's generic coverage format.

  sonar_coverage.py --xcresult PATH --root DIR [--include DIR ...] --output FILE
  sonar_coverage.py --lcov PATH --root DIR [--include DIR ...] --output FILE

--xcresult reads an Xcode result bundle through `xcrun xccov`. --lcov reads an
lcov file, such as the one `llvm-cov export -format=lcov` writes for Codecov.
Only files under --root are kept, and their paths are written relative to it,
so the report can be read by a job with its checkout somewhere else. Each
--include (relative to --root) narrows that to files under one of those folders.
The input and output files must be under --root too.

The same file is used by CucumberSwift and CucumberSwiftExpressions; keep the
two copies identical.
"""
import argparse
import json
import os
import subprocess
import sys
import xml.etree.ElementTree as ET


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


def inside(root, path, name):
    """The absolute path of a file argument, which must be under root."""
    full = os.path.realpath(path)
    if not under(root, full):
        fail(f"{name} {path} is not under --root")
    return full


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


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--xcresult")
    source.add_argument("--lcov")
    parser.add_argument("--root", required=True)
    parser.add_argument("--include", action="append", default=[])
    parser.add_argument("--output", required=True)
    args = parser.parse_args(argv)
    root = os.path.realpath(args.root)
    output = inside(root, args.output, "--output")

    if args.xcresult:
        # An absolute path, so xccov can never read it as an option.
        xcresult = inside(root, args.xcresult, "--xcresult")
        result = subprocess.run(
            ["xcrun", "xccov", "view", "--archive", "--json", xcresult],
            capture_output=True, text=True, check=False)
        if result.returncode != 0:
            fail(f"xccov could not read {args.xcresult}: {result.stderr.strip()}")
        coverage = from_xccov(json.loads(result.stdout))
    else:
        with open(inside(root, args.lcov, "--lcov"), encoding="utf-8") as handle:
            coverage = from_lcov(handle.read())

    coverage = relative_to_root(coverage, root, args.include)
    if not coverage:
        fail(f"no covered files under {args.root} {' '.join(args.include)}".rstrip())
    with open(output, "w", encoding="utf-8") as handle:
        handle.write(to_xml(coverage))
    lines = sum(len(lines) for lines in coverage.values())
    print(f"Wrote coverage for {len(coverage)} files ({lines} lines) to {args.output}")


if __name__ == "__main__":
    main()
