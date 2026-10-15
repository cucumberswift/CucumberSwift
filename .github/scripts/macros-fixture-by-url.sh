#!/usr/bin/env bash
# Makes Fixtures/StepDefinitionMacrosPackage depend on CucumberSwift by URL, as a project does, instead of
# by path, so that the fixture's build and tests also check that the Macros trait resolves from a URL. The
# URL is a bare git repository of the checked-out commit, tagged 999.0.0, in <directory>. SwiftPM resolves
# a package from a URL differently from a path: before Swift 6.4, it resolves the Macros trait only when
# the project declares swift-syntax too, as "Checking Step Definitions When They Compile" says (#418). So
# the script declares swift-syntax as that article shows, with the range Package@swift-6.1.swift accepts.
# Used by CI's Fixture tests, before `mise run test-fixtures`.
#
#   .github/scripts/macros-fixture-by-url.sh <directory>
#
# It changes the fixture's Package.swift in this checkout; `git checkout` the file to put it back. The
# manifest in the repository keeps its path dependency and no swift-syntax: a dependency from a URL with
# no committed Package.resolved is a SonarCloud finding (swift:S7694), and a path doesn't need it.
# Before it adds swift-syntax, the script resolves the same setup without it, and only says whether that
# still fails: when it no longer does with the oldest Swift the docs give, the docs can drop swift-syntax.
set -euo pipefail

dir=${1:?usage: macros-fixture-by-url.sh <directory>}
fixture=Fixtures/StepDefinitionMacrosPackage
manifest="$fixture/Package.swift"
repo="$(cd "$dir" && pwd -P)/CucumberSwift.git"
version=999.0.0
path_dependency='.package(name: "CucumberSwift", path: "../..", traits: ["Macros"])'
url_dependency=".package(url: \"file://$repo\", from: \"$version\", traits: [\"Macros\"])"

# The range of swift-syntax versions the macros accept, as the article shows it.
range=$(sed -nE 's|.*swift-syntax\.git", ("[0-9.]+"\.\.<"[0-9.]+")\).*|\1|p' Package@swift-6.1.swift)
if [ -z "$range" ]; then
  echo "::error file=Package@swift-6.1.swift::Can't find the range of swift-syntax versions" >&2
  exit 1
fi
swift_syntax_dependency=".package(url: \"https://github.com/swiftlang/swift-syntax.git\", $range)"

# A local clone copies every object, so the commit is there even when the checkout is shallow and detached.
rm -rf "$repo"
git clone --quiet --bare . "$repo"
git -C "$repo" tag "$version" "$(git rev-parse HEAD)"

# Replaces <old> with <new> in the manifest, and fails if <old> isn't there exactly once.
replace_in_manifest() {
  python3 - "$manifest" "$1" "$2" <<'EOF'
import pathlib
import sys

path, old, new = pathlib.Path(sys.argv[1]), sys.argv[2], sys.argv[3]
text = path.read_text(encoding="utf-8")
if text.count(old) != 1:
    print(f"::error file={path}::Can't find the dependency to replace, once: {old}", file=sys.stderr)
    sys.exit(1)
path.write_text(text.replace(old, new), encoding="utf-8")
EOF
}

replace_in_manifest "$path_dependency" "$url_dependency"
grep -F "$url_dependency" "$manifest"

# The same setup without swift-syntax. Only a notice either way: a newer Swift on the runner must not fail CI.
without="$dir/without-swift-syntax"
rm -rf "$without"
mkdir -p "$without"
(cd "$fixture" && find . -path ./.build -prune -o -type f -print | cpio -pdm --quiet "$without")
if output=$(swift package --package-path "$without" resolve 2>&1); then
  echo "::notice::$(swift --version 2>/dev/null | head -1): the Macros trait resolves from a URL without swift-syntax declared. Once it does with the oldest Swift the docs give, they can drop it (#418)."
else
  echo "$output" | tail -3
  echo "Without swift-syntax declared, resolving the Macros trait from a URL still fails, as the docs say."
fi
rm -rf "$without"

# The setup the article shows: swift-syntax next to CucumberSwift.
replace_in_manifest "$url_dependency" "$url_dependency,
        $swift_syntax_dependency"
grep -F "$swift_syntax_dependency" "$manifest"
