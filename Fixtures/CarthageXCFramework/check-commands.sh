#!/bin/bash
# Runs the cucumberswift-cli commands that a Carthage project can run besides the Run Script phase's lint, through
# cucumberswift.sh as the project does: fix-feature-files and generate. The build phase runs lint.

set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
export CUCUMBERSWIFT_CHECKOUT="$here/../.."
work="$(mktemp -d "${TMPDIR:-/tmp}/carthage-commands.XXXXXX")"
trap 'rm -rf "$work"' EXIT

cp "$here/Tests/Features/Basket.feature" "$work/Basket.feature"
sed -i.bak 's/^    Given /    Giben /' "$work/Basket.feature"
rm "$work/Basket.feature.bak"

"$here/cucumberswift.sh" lint --stamp "$work/stamp" --features "$work/Basket.feature" --step-definitions "$here/Tests/StepDefinitions.swift" > "$work/lint.out"
grep -q "Did you mean 'Given'" "$work/lint.out" || { echo "lint did not report the misspelt keyword: $(cat "$work/lint.out")"; exit 1; }

"$here/cucumberswift.sh" fix-feature-files "$work/Basket.feature" > "$work/fix.out"
grep -q "^    Given I have 3 cukes" "$work/Basket.feature" || { echo "fix-feature-files did not fix the keyword: $(cat "$work/fix.out")"; exit 1; }
diff "$here/Tests/Features/Basket.feature" "$work/Basket.feature" || { echo "fix-feature-files changed more than the keyword"; exit 1; }

# generate needs Swift 6.1: Package@swift-6.0.swift, which Swift 6.0 reads, leaves it out and the command says so.
swift_version="$(swift --version 2>&1 | sed -n 's/.*Swift version \([0-9]*\.[0-9]*\).*/\1/p' | head -n 1)"
if [ "$(printf '%s\n6.1\n' "$swift_version" | sort -V | head -n 1)" = "6.1" ]; then
  "$here/cucumberswift.sh" generate --output "$work/Generated.swift" "$work/Basket.feature"
  grep -q "Typed arguments from Cucumber expressions" "$work/Generated.swift" || { echo "generate wrote no test for the scenario"; exit 1; }
else
  status=0
  "$here/cucumberswift.sh" generate --output "$work/Generated.swift" "$work/Basket.feature" > "$work/generate.out" 2>&1 || status=$?
  [ "$status" = 2 ] || { echo "generate on Swift $swift_version should exit with status 2, not $status: $(cat "$work/generate.out")"; exit 1; }
  grep -q "needs Swift 6.1 or later" "$work/generate.out" || { echo "generate did not say that it needs Swift 6.1: $(cat "$work/generate.out")"; exit 1; }
fi
echo "The cucumberswift-cli commands ran from the checkout."
