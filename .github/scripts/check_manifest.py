#!/usr/bin/env python3
"""Check which manifest a toolchain reads.

Swift 6.0 (Xcode 16.0 to 16.2) reads Package@swift-6.0.swift. Swift 6.1 and later
read Package.swift, which adds the macros and Swift Testing. CI runs this with each
toolchain it proves that for, and the Swift Package Index reads the package the
same way, with `swift package dump-package`.

  python3 .github/scripts/check_manifest.py <manifest>
  swift package dump-package | python3 .github/scripts/check_manifest.py <manifest> -

It reads `swift package dump-package`'s output (run here, or from standard input
with `-`), and fails unless the tools version in it is the one <manifest> declares.
The two manifests declare different tools versions, so that tells them apart. It
prints the products, so the log shows what the toolchain sees.

Only the standard library is used.
"""
import json
import re
import subprocess
import sys

TOOLS_VERSION = re.compile(r"^// swift-tools-version:\s*([0-9]+(?:\.[0-9]+){0,2})")


def normalized(version):
    """6.1 and 6.1.0 compare equal."""
    parts = [int(part) for part in version.split(".")]
    return tuple(parts + [0] * (3 - len(parts)))


def declared_tools_version(text, path):
    match = TOOLS_VERSION.match(text)
    if not match:
        raise ValueError(f"{path} has no swift-tools-version line")
    return match.group(1)


def check(manifest_path, manifest_text, dump):
    """Return (ok, message) for a dump-package JSON string."""
    expected = declared_tools_version(manifest_text, manifest_path)
    package = json.loads(dump)
    read = package["toolsVersion"]["_version"]
    products = ", ".join(f"{product['name']} ({next(iter(product['type']))})"
                         for product in package["products"])
    if normalized(read) != normalized(expected):
        return False, (f"This toolchain read a manifest with tools version {read}, not "
                       f"{manifest_path} (tools version {expected}). Products: {products}")
    return True, f"This toolchain read {manifest_path} (tools version {read}). Products: {products}"


def main(argv):
    if len(argv) not in (2, 3) or (len(argv) == 3 and argv[2] != "-"):
        print(__doc__.strip().split("\n\n")[1], file=sys.stderr)
        return 2
    manifest_path = argv[1]
    with open(manifest_path, encoding="utf-8") as handle:
        manifest_text = handle.read()
    if len(argv) == 3:
        dump = sys.stdin.read()
    else:
        dump = subprocess.run(["swift", "package", "dump-package"], check=True,
                              capture_output=True, text=True).stdout
    ok, message = check(manifest_path, manifest_text, dump)
    print(message if ok else f"::error file={manifest_path}::{message}")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
