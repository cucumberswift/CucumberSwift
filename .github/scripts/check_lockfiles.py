#!/usr/bin/env python3
"""Check that each dependency manifest agrees with its lockfile.

The repository has two manifests, each with its own lockfile:

  Package.swift          -> Package.resolved (SwiftPM)
  Project.swift (Tuist)  -> CucumberSwift.xcodeproj/.../swiftpm/Package.resolved
                            (Xcode, CI's test jobs, and Carthage users)

The Xcode side is read from project.pbxproj, which is what xcodebuild resolves
from. The project_drift job in CI.yml checks that it matches Project.swift.

This fails when:

  1. a manifest's lower bound is not the version its lockfile pins;
  2. the two lockfiles pin a different version or revision of a package that
     both contain;
  3. with --resolve, a lockfile is stale or does not satisfy its manifest.

Run from the repository root:

  python3 .github/scripts/check_lockfiles.py            # checks 1 and 2
  python3 .github/scripts/check_lockfiles.py --resolve  # and 3 (needs swift and xcodebuild)

Only the standard library is used.
"""
import json
import re
import subprocess
import sys

PACKAGE_SWIFT = "Package.swift"
PACKAGE_RESOLVED = "Package.resolved"
XCODE_PROJECT = "CucumberSwift.xcodeproj"
PBXPROJ = f"{XCODE_PROJECT}/project.pbxproj"
XCODE_RESOLVED = f"{XCODE_PROJECT}/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"

# How to fix each side, for the error messages.
FIX_SWIFTPM = f"Edit {PACKAGE_SWIFT}, then run `swift package resolve` and commit {PACKAGE_RESOLVED}."
FIX_XCODE = (f"Edit Project.swift and run `mise run generate`, then run "
             f"`xcodebuild -resolvePackageDependencies -project {XCODE_PROJECT}` and commit "
             f"the project and {XCODE_RESOLVED}.")

# The version argument of a SwiftPM requirement. `from:` and the
# `.upToNext...(from:)` forms have a lower bound; so do `exact:` and a range.
REQUIREMENT = re.compile(
    r'(?:\bfrom|\bexact)\s*:\s*"([^"]+)"'
    r'|\.(?:upToNextMajor|upToNextMinor)\s*\(\s*from\s*:\s*"([^"]+)"'
    r'|\.exact\s*\(\s*"([^"]+)"'
    r'|"([^"]+)"\s*\.\.[.<]')
# The start of a string literal: a `"`, after any `#`s of a raw string's delimiter.
STRING_START = re.compile(r'#*"')
URL = re.compile(r'\burl\s*:\s*"([^"]+)"')
# A pbxproj value is either quoted or a bare word. The two forms are separate
# alternatives so that the pattern cannot backtrack between them.
PBX_VALUE = r'(?:"([^"]*)"|([^";\s]*))'
PBX_REFERENCE = re.compile(
    r"isa = XCRemoteSwiftPackageReference;\s*repositoryURL = " + PBX_VALUE + r";\s*"
    r"requirement = \{([^{}]*)\};")
PBX_FIELD = re.compile(r"(\w+) = " + PBX_VALUE + ";")


class CheckError(Exception):
    """A file this check cannot read."""


def identity(url):
    """SwiftPM's package identity: the last path component, lowercased, without .git."""
    name = url.rstrip("/").rsplit("/", 1)[-1].lower()
    return name[:-4] if name.endswith(".git") else name


def same_repository(first, second):
    """Whether two URLs name the same repository, ignoring case, a trailing / and .git."""
    def normalized(url):
        url = url.lower().rstrip("/")
        return url[:-4] if url.endswith(".git") else url
    return normalized(first) == normalized(second)


def string_end(text, index):
    """The index just after the string literal that starts at `index`: a `"`, or `#`s
    and a `"` for a raw string such as `#"C:\"#`, which only `"#` ends. Handles
    escapes (`\\` followed by as many `#`s) and multiline (triple-quoted) strings; an
    unterminated string runs to the end."""
    hashes = STRING_START.match(text, index).end() - 1 - index
    index += hashes
    quote = '"' * 3 if text.startswith('"' * 3, index) else '"'
    close, escape = quote + "#" * hashes, "\\" + "#" * hashes
    index += len(quote)
    while index < len(text) and not text.startswith(close, index):
        index += len(escape) + 1 if text.startswith(escape, index) else 1
    return min(index + len(close), len(text))


def block_comment_end(text, index):
    """The index just after the `/* */` comment that starts at `index`. They nest."""
    depth, index = 1, index + 2
    while depth and index < len(text):
        pair = text[index:index + 2]
        depth += {"/*": 1, "*/": -1}.get(pair, 0)
        index += 2 if pair in ("/*", "*/") else 1
    return index


def strip_comments(text):
    """Swift source without its comments: `//` to the end of the line, and `/* */`,
    which nest. String literals are kept as they are, so `//` in a URL survives."""
    out, index = [], 0
    while index < len(text):
        pair = text[index:index + 2]
        if pair == "/*":
            index = block_comment_end(text, index)
        elif pair == "//":
            newline = text.find("\n", index)
            index = len(text) if newline < 0 else newline
        else:
            end = string_end(text, index) if STRING_START.match(text, index) else index + 1
            out.append(text[index:end])
            index = end
    return "".join(out)


def call_end(text, index):
    """The index of the `)` closing a call whose arguments start at `index`, or None.
    Parentheses inside a string literal do not count."""
    depth = 1
    while index < len(text):
        if STRING_START.match(text, index):
            index = string_end(text, index)
            continue
        depth += {"(": 1, ")": -1}.get(text[index], 0)
        if depth == 0:
            return index
        index += 1
    return None


def package_calls(text):
    """Yield the argument text of each `.package(...)` call."""
    for match in re.finditer(r"\.package\s*\(", text):
        end = call_end(text, match.end())
        if end is not None:
            yield text[match.end():end]


def parse_package_swift(text):
    """Return {identity: (url, lower bound)} for each remote dependency."""
    dependencies = {}
    for arguments in package_calls(strip_comments(text)):
        url = URL.search(arguments)
        if not url:
            continue  # a local `path:` package has no lockfile pin
        requirement = REQUIREMENT.search(arguments)
        if not requirement:
            raise CheckError(f"{PACKAGE_SWIFT}: {url.group(1)} has no version requirement this "
                             f"check can read. Use a version range such as `from: \"1.2.0\"`.")
        bound = next(group for group in requirement.groups() if group)
        dependencies[identity(url.group(1))] = (url.group(1), bound)
    return dependencies


def parse_pbxproj(text):
    """Return {identity: (url, lower bound)} for each XCRemoteSwiftPackageReference."""
    dependencies = {}
    for quoted_url, bare_url, body in PBX_REFERENCE.findall(text):
        url = quoted_url or bare_url
        fields = {name: quoted or bare for name, quoted, bare in PBX_FIELD.findall(body)}
        bound = fields.get("minimumVersion") or fields.get("version")
        if not bound:
            raise CheckError(f"{PBXPROJ}: {url} has a `{fields.get('kind', 'unknown')}` "
                             f"requirement, not a version range. Use `.upToNextMajor(from:)` "
                             f"in Project.swift.")
        dependencies[identity(url)] = (url, bound)
    return dependencies


def parse_resolved(text, path):
    """Return {identity: {url, version, revision}} for each pin, from any lockfile format."""
    try:
        data = json.loads(text)
        version = data["version"]
        pins = data["object"]["pins"] if version == 1 else data["pins"]
        result = {}
        for pin in pins:
            url = pin["repositoryURL"] if version == 1 else pin["location"]
            state = pin["state"]
            result[identity(url)] = {"url": url, "version": state.get("version"),
                                     "revision": state.get("revision")}
        return result
    except (ValueError, KeyError, TypeError) as error:
        raise CheckError(f"{path} is not a Package.resolved file this check can read ({error}).")


def check_bounds(manifest, dependencies, lockfile, pins, fix):
    """Errors for each direct dependency whose lower bound is not its locked version."""
    errors = []
    for name, (url, bound) in sorted(dependencies.items()):
        pin = pins.get(name)
        if pin is None:
            errors.append(f"{lockfile} has no pin for {url}, which {manifest} requires. {fix}")
        elif not same_repository(pin["url"], url):
            errors.append(f"{manifest} requires {url}, but {lockfile} pins {pin['url']}, a "
                          f"different repository with the same package identity. {fix}")
        elif pin["version"] is None:
            errors.append(f"{lockfile} pins {url} to a branch or revision, not a version. {fix}")
        elif pin["version"] != bound:
            errors.append(f"{manifest} requires {url} from {bound}, but {lockfile} pins "
                          f"{pin['version']}. Set the lower bound in {manifest} to "
                          f"{pin['version']}, the version CI builds against. {fix}")
    return errors


def check_shared(swiftpm_pins, xcode_pins):
    """Errors for each package both lockfiles pin, where they disagree."""
    errors = []
    for name in sorted(swiftpm_pins.keys() & xcode_pins.keys()):
        ours, theirs = swiftpm_pins[name], xcode_pins[name]
        if not same_repository(ours["url"], theirs["url"]):
            errors.append(
                f"The lockfiles pin different repositories with the same package identity: "
                f"{PACKAGE_RESOLVED} pins {ours['url']}, {XCODE_RESOLVED} pins {theirs['url']}. "
                f"Use the same URL in {PACKAGE_SWIFT} and Project.swift, then re-resolve. "
                f"For {PACKAGE_RESOLVED}: {FIX_SWIFTPM} For the Xcode lockfile: {FIX_XCODE}")
        elif (ours["version"], ours["revision"]) != (theirs["version"], theirs["revision"]):
            errors.append(
                f"The lockfiles disagree on {ours['url']}: {PACKAGE_RESOLVED} pins "
                f"{ours['version']} ({ours['revision']}), {XCODE_RESOLVED} pins "
                f"{theirs['version']} ({theirs['revision']}). Update the one that is behind, "
                f"raising its manifest's lower bound to match. For {PACKAGE_RESOLVED}: "
                f"{FIX_SWIFTPM} For the Xcode lockfile: {FIX_XCODE}")
    return errors


def read(path):
    with open(path, encoding="utf-8") as handle:
        return handle.read()


def check_files():
    """Checks 1 and 2, on the files in the working directory."""
    swiftpm_pins = parse_resolved(read(PACKAGE_RESOLVED), PACKAGE_RESOLVED)
    xcode_pins = parse_resolved(read(XCODE_RESOLVED), XCODE_RESOLVED)
    return (check_bounds(PACKAGE_SWIFT, parse_package_swift(read(PACKAGE_SWIFT)),
                         PACKAGE_RESOLVED, swiftpm_pins, FIX_SWIFTPM)
            + check_bounds("Project.swift", parse_pbxproj(read(PBXPROJ)),
                           XCODE_RESOLVED, xcode_pins, FIX_XCODE)
            + check_shared(swiftpm_pins, xcode_pins))


def run(*args):
    """Run a command, streaming its output to the log. Return its exit status."""
    print(f"$ {' '.join(args)}", flush=True)
    return subprocess.run(args).returncode


def check_resolve():
    """Check 3: resolve each lockfile against its manifest, and fail if it changes."""
    errors = []
    if run("swift", "package", "resolve") != 0:
        errors.append(f"`swift package resolve` failed, so {PACKAGE_RESOLVED} cannot satisfy "
                      f"{PACKAGE_SWIFT}. {FIX_SWIFTPM}")
    elif run("git", "diff", "--exit-code", "--", PACKAGE_RESOLVED) != 0:
        errors.append(f"{PACKAGE_RESOLVED} is stale: `swift package resolve` changed it (diff "
                      f"above). {FIX_SWIFTPM}")
    # -disableAutomaticPackageResolution makes xcodebuild fail, rather than
    # re-resolve, when the lockfile does not satisfy the project.
    if run("xcodebuild", "-resolvePackageDependencies", "-project", XCODE_PROJECT,
           "-disableAutomaticPackageResolution") != 0:
        errors.append(f"{XCODE_RESOLVED} does not satisfy {PBXPROJ}: xcodebuild would have to "
                      f"re-resolve it (error above). {FIX_XCODE}")
    elif run("git", "diff", "--exit-code", "--", XCODE_RESOLVED) != 0:
        errors.append(f"{XCODE_RESOLVED} is stale: xcodebuild changed it (diff above). "
                      f"{FIX_XCODE}")
    return errors


def main(argv):
    try:
        errors = check_files()
    except (CheckError, OSError) as error:
        errors = [str(error)]
    if "--resolve" in argv:
        errors += check_resolve()
    for error in errors:
        print(f"::error::{error}")
    if errors:
        return 1
    print("Every manifest agrees with its lockfile, and the two lockfiles agree.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
