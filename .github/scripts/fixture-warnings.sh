#!/usr/bin/env bash
# Checks the warnings from CucumberSwift in a fixture's build and test output. Fails if the output has
# a warning from CucumberSwift that the fixture's expected-warnings file doesn't list, or lacks one it
# does list. A fixture without that file must have no warnings from CucumberSwift at all.
#
#   .github/scripts/fixture-warnings.sh <fixture folder> <output file>
#
# A warning comes from CucumberSwift, rather than from the fixture's own code, when it is:
# - CucumberSwiftLint's: on a feature file, or on a step definition whose pattern can't match;
# - in a step definition macro's expansion;
# - in a file of this repository outside Fixtures/: the library, the plugins and the tools;
# - SwiftPM's, about the CucumberSwift package.
# Each expected-warnings line, other than comments and blank lines, is the end of a warning's
# file path followed by the rest of its line. Used by `mise run test-fixtures` and by CI.
set -euo pipefail

fixture=${1:?usage: fixture-warnings.sh <fixture folder> <output file>}
log=${2:?usage: fixture-warnings.sh <fixture folder> <output file>}
name=$(basename "$fixture")
# The checkout's path as given and with symbolic links resolved, since tools print either.
root="$(cd "$(dirname "$0")/../.." && pwd)/"
real_root="$(cd "$root" && pwd -P)/"
expected="$fixture/expected-warnings"

found=$(awk -v root="$root" -v real_root="$real_root" '
  # macOS reaches /tmp and /var through /private, and xcodebuild prints them without it.
  function plain(p) { sub(/^\/private\//, "/", p); return p }
  function in_repo(path, base) {
    path = plain(path); base = plain(base)
    return index(path, base) == 1 && index(path, base "Fixtures/") != 1
  }
  /^warning: .cucumberswift.: / { print; next }
  match($0, /:[0-9]+:[0-9]+: warning: /) {
    path = substr($0, 1, RSTART - 1)
    message = substr($0, RSTART + RLENGTH)
    if (path ~ /\.feature$/ || path ~ /@__swiftmacro_/ \
        || message ~ /^(This step definition can never match|This regular expression does not compile)/ \
        || in_repo(path, root) || in_repo(path, real_root)) print
  }' "$log" | sort -u)

status=0
expected_lines=()
if [[ -f "$expected" ]]; then
  while IFS= read -r line; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    expected_lines+=("$line")
    if ! grep -qF -- "$line" <<<"$found"; then
      echo "error: $name: the output does not contain, as expected-warnings requires: $line"
      status=1
    fi
  done < "$expected"
fi

while IFS= read -r warning; do
  [[ -z "$warning" ]] && continue
  listed=false
  for line in ${expected_lines[@]+"${expected_lines[@]}"}; do
    if [[ "$warning" == *"$line" ]]; then listed=true; break; fi
  done
  if [[ "$listed" == false ]]; then
    echo "error: $name: a warning from CucumberSwift that expected-warnings doesn't list: $warning"
    status=1
  fi
done <<<"$found"

if [[ "$status" -eq 0 ]]; then
  echo "$name: every warning from CucumberSwift is expected ($(grep -c . <<<"$found" || true) in all)."
fi
exit "$status"
