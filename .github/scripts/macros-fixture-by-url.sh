#!/usr/bin/env bash
# Makes Fixtures/StepDefinitionMacrosPackage depend on CucumberSwift by URL, as a project does, instead of
# by path, so that the fixture's build and tests also check that the Macros trait resolves from a URL. The
# URL is a bare git repository of the checked-out commit, tagged 999.0.0, in <directory>. SwiftPM resolves
# a package from a URL differently from a path: before Swift 6.4, it resolves the Macros trait only when
# the project declares swift-syntax too, as "Checking Step Definitions When They Compile" says and the
# fixture does (#418). Used by CI's Fixture tests, before `mise run test-fixtures`.
#
#   .github/scripts/macros-fixture-by-url.sh <directory>
#
# It changes the fixture's Package.swift in this checkout; `git checkout` the file to put it back. It
# then resolves the same setup without swift-syntax, and only says whether that still fails: when it no
# longer does with the oldest Swift the docs give, the docs can drop swift-syntax.
set -euo pipefail

dir=${1:?usage: macros-fixture-by-url.sh <directory>}
fixture=Fixtures/StepDefinitionMacrosPackage
manifest="$fixture/Package.swift"
repo="$(cd "$dir" && pwd -P)/CucumberSwift.git"
version=999.0.0
path_dependency='.package(name: "CucumberSwift", path: "../..", traits: ["Macros"])'
url_dependency=".package(url: \"file://$repo\", from: \"$version\", traits: [\"Macros\"])"

# A local clone copies every object, so the commit is there even when the checkout is shallow and detached.
rm -rf "$repo"
git clone --quiet --bare . "$repo"
git -C "$repo" tag "$version" "$(git rev-parse HEAD)"

if ! grep -qF "$path_dependency" "$manifest"; then
  echo "::error file=$manifest::Can't find the CucumberSwift dependency to replace: $path_dependency"
  exit 1
fi
sed -i '' "s|$(printf '%s' "$path_dependency" | sed 's/[][\.*^$|]/\\&/g')|$url_dependency|" "$manifest"
grep -F "$url_dependency" "$manifest"

# The same setup without swift-syntax. Only a notice either way: a newer Swift on the runner must not fail CI.
without="$dir/without-swift-syntax"
rm -rf "$without"
mkdir -p "$without"
(cd "$fixture" && find . -path ./.build -prune -o -type f -print | cpio -pdm --quiet "$without")
sed -i '' '/swiftlang\/swift-syntax/d' "$without/Package.swift"
if output=$(swift package --package-path "$without" resolve 2>&1); then
  echo "::notice::$(swift --version 2>/dev/null | head -1): the Macros trait resolves from a URL without swift-syntax declared. Once it does with the oldest Swift the docs give, they can drop it (#418)."
else
  echo "$output" | tail -3
  echo "Without swift-syntax declared, resolving the Macros trait from a URL still fails, as the docs say."
fi
rm -rf "$without"
