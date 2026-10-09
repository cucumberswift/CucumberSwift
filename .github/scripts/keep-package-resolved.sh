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
cp -p "$lockfile" "$saved"
# Also when the command is interrupted.
trap 'cmp -s "$saved" "$lockfile" || cp -p "$saved" "$lockfile"; rm -f "$saved"' EXIT
"$@"
