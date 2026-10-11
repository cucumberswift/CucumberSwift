#!/usr/bin/env bash
# Runs a command and then puts this checkout's Package.resolved back as it was, keeping the command's
# exit status.
#
#   .github/scripts/keep-package-resolved.sh <command> [arguments...]
#
# For commands that resolve an Xcode project depending on this checkout as a local package, such as
# `tuist generate` (which runs `xcodebuild -resolvePackageDependencies`) and `xcodebuild test`. Xcode's
# resolution writes the checkout's own Package.resolved for the traits that project enables. Without
# the Macros trait it drops the swift-syntax pin and changes `originHash`, over the lockfile resolved
# with every trait on. Used by `mise run test-fixtures`, `mise run generate-fixtures` and
# .github/scripts/parallel-fixture.sh.
set -uo pipefail

lockfile="$(cd "$(dirname "$0")/../.." && pwd)/Package.resolved"
saved=$(mktemp)
had_lockfile=false
if [[ -e "$lockfile" ]]; then
  cp -p "$lockfile" "$saved" || { rm -f "$saved"; echo "Cannot save $lockfile" >&2; exit 1; }
  had_lockfile=true
fi
# Keeps the command's exit status, unless it succeeded and the file can't be put back.
restore() {
  local status=$?
  if [[ "$had_lockfile" == true ]]; then
    if ! cmp -s "$saved" "$lockfile" && ! cp -p "$saved" "$lockfile"; then
      echo "Cannot restore $lockfile; a copy is at $saved" >&2
      exit "$((status == 0 ? 1 : status))"
    fi
  else
    rm -f "$lockfile"
  fi
  rm -f "$saved"
  exit "$status"
}
# Also when the command is interrupted.
trap restore EXIT
"$@"
