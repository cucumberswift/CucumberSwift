#!/usr/bin/env python3
"""Fail a change that adds a public API or a setting without a scenario in the parity suite.

The parity suite in Fixtures/Parity (#561) has a scenario for every user-facing behaviour. This
check keeps it that way. It lists the public declarations in the sources of both runners and
their macros, and the settings in the Settings article's table, and every one must be in
Fixtures/Parity/api.json:

  covered   the declaration, with the feature file and the title of the scenario that uses it;
  baseline  the declarations that were public before this check: they have no scenario yet.

A new public declaration or setting is in neither, so this fails, naming it. Add a scenario to
Fixtures/Parity/Shared/Features that uses it, and list it under `covered` with that scenario.
A listed scenario that is missing from its feature file fails too, and so does an entry for a
declaration that no longer exists, so the file never goes stale. When a declaration is renamed or
its signature changes, move its entry to the new name. Only `baseline` entries are removed
without a scenario, when their declaration is deleted.

  python3 .github/scripts/parity_coverage.py            check
  python3 .github/scripts/parity_coverage.py --update   list every new declaration under `baseline`
                                                         and drop the entries that went stale

--update is for the maintainers when a declaration should have no scenario. CONTRIBUTING.md says
how a baseline entry is approved.

A declaration is a line of a Swift file under Sources/ that starts with `public` or `open`
(after attributes), up to its `{`, `=` or end of line, with its spaces collapsed and keyed with
its file. The generated localized step typealiases (Generated/I18n.swift and
LocalizedStepTypes.swift) and the localized macro declarations are not listed one by one: they
are the same declaration in each language. Only the standard library is used.
"""
import json
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
API = os.path.join(ROOT, "Fixtures", "Parity", "api.json")
FEATURES = os.path.join(ROOT, "Fixtures", "Parity", "Shared", "Features")
SETTINGS = os.path.join(ROOT, "Sources", "CucumberSwift", "CucumberSwift.docc", "Settings.md")
SOURCES = ("CucumberSwift", "CucumberSwiftTesting", "CucumberSwiftMacros", "CucumberSwiftTestingMacros")
# The same declaration in each language: one entry for each folder or file.
LOCALIZED = ("Generated/I18n.swift", "LocalizedStepTypes.swift", "LocalizedDSLStepMacros.swift",
             "LocalizedStepDefinitionMacros.swift")

# An attribute at the start of a line, such as `@MainActor` or `@available(macOS 13, *)`.
ATTRIBUTE = re.compile(r"@[\w.]+(?:\([^)]*\))?\s+")
PUBLIC = re.compile(r"(?:public|open)\b(?!\s*\()")
SETTING = re.compile(r"^\|\s*`((?:Cucumber|StepImplementation)\.[A-Za-z]+(?:\([^`]*\))?)`")
SCENARIO = re.compile(r"^\s*(?:Scenario Outline|Scenario|Example):\s*(.+?)\s*$")


class CoverageError(Exception):
    """A file this check reads that is missing or isn't valid."""


def is_declaration(line):
    """Whether a line of Swift starts a public or open declaration, after any attributes."""
    text = line.lstrip()
    if text.startswith("//"):
        return False
    match = ATTRIBUTE.match(text)
    while match:
        text = text[match.end():]
        match = ATTRIBUTE.match(text)
    return bool(PUBLIC.match(text))


def signature(line):
    """A declaration's line up to its `{` or `=`, with its spaces collapsed."""
    text = re.split(r"[{=]", line, maxsplit=1)[0]
    return re.sub(r"\s+", " ", text).strip().rstrip(",").strip()


def swift_files():
    """The path under Sources/ of each Swift file of both runners and their macros, and its full path."""
    for source in SOURCES:
        for directory, _, files in os.walk(os.path.join(ROOT, "Sources", source)):
            for name in sorted(files):
                if name.endswith(".swift"):
                    path = os.path.join(directory, name)
                    yield os.path.relpath(path, os.path.join(ROOT, "Sources")), path


def declarations():
    """{key: line number} for each public declaration, keyed by `path::signature`."""
    found = {}
    for relative, path in swift_files():
        if relative.endswith(LOCALIZED):
            found[f"{relative}::(localized declarations)"] = 1
            continue
        with open(path, encoding="utf-8") as f:
            for number, line in enumerate(f, start=1):
                if is_declaration(line):
                    found.setdefault(f"{relative}::{signature(line)}", number)
    return found


def settings():
    """The settings in the Settings article's table, such as `Cucumber.reportPath`."""
    found = {}
    with open(SETTINGS, encoding="utf-8") as f:
        for number, line in enumerate(f, start=1):
            match = SETTING.match(line)
            if match:
                found[f"setting::{match.group(1)}"] = number
    return found


def scenarios():
    """{feature file: {scenario titles}} in the parity suite's feature files."""
    found = {}
    for name in sorted(os.listdir(FEATURES)):
        if name.endswith(".feature"):
            with open(os.path.join(FEATURES, name), encoding="utf-8") as f:
                found[name] = {m.group(1) for m in map(SCENARIO.match, f) if m}
    return found


def read_api():
    try:
        with open(API, encoding="utf-8") as f:
            api = json.load(f)
    except FileNotFoundError as error:
        raise CoverageError(f"{os.path.relpath(API, ROOT)} doesn't exist") from error
    except json.JSONDecodeError as error:
        raise CoverageError(f"{os.path.relpath(API, ROOT)} isn't valid JSON: {error}") from error
    if not isinstance(api.get("covered"), dict) or not isinstance(api.get("baseline"), list):
        raise CoverageError("api.json needs `covered`, an object, and `baseline`, a list")
    return api


def check(found, api, available):
    """The errors for the declarations `found` against `api`, with the scenarios `available`."""
    errors = []
    covered, baseline = api["covered"], set(api["baseline"])
    for key, entry in sorted(covered.items()):
        feature, title = entry.get("feature"), entry.get("scenario")
        if title not in available.get(feature, set()):
            errors.append(f"error: {key} is covered by the scenario {title!r} in {feature}, which doesn't exist in "
                          f"Fixtures/Parity/Shared/Features.")
        if key in baseline:
            errors.append(f"error: {key} is in `covered` and in `baseline`. Remove it from `baseline`.")
    for key in sorted(found):
        if key not in covered and key not in baseline:
            where = f"line {found[key]}" if found[key] > 1 else "its file"
            errors.append(f"error: {key} ({where}) is public, or a setting, and has no scenario in the parity suite. "
                          f"Add a scenario to Fixtures/Parity/Shared/Features that uses it, and list it under "
                          f"`covered` in Fixtures/Parity/api.json. See \"The parity suite\" in CONTRIBUTING.md.")
    for key in sorted((set(covered) | baseline) - set(found)):
        errors.append(f"error: api.json lists {key}, which isn't in the sources any more. Move its entry to the "
                      f"declaration's new name, or remove it if the declaration is gone.")
    return errors


def main(argv):
    update = "--update" in argv[1:]
    try:
        found = {**declarations(), **settings()}
        api = read_api()
        if update:
            covered = api["covered"]
            baseline = sorted((set(found) - set(covered)))
            api = {"covered": covered, "baseline": baseline}
            with open(API, "w", encoding="utf-8") as f:
                json.dump(api, f, indent=2, ensure_ascii=False, sort_keys=True)
                f.write("\n")
            print(f"Wrote {len(covered)} covered and {len(baseline)} baseline entries to {os.path.relpath(API, ROOT)}.")
            return 0
        errors = check(found, api, scenarios())
    except (CoverageError, OSError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    for error in errors:
        print(error, file=sys.stderr)
    if errors:
        return 1
    print(f"Every public declaration and setting ({len(found)}) has a parity scenario or is in the baseline.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
