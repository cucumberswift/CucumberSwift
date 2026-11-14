#!/bin/bash
# Runs the cucumberswift commands that a Carthage project can run besides the Run Script phase's lint, through
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

"$here/cucumberswift.sh" generate --output "$work/Generated.swift" "$work/Basket.feature"
grep -q "Typed arguments from Cucumber expressions" "$work/Generated.swift" || { echo "generate wrote no test for the scenario"; exit 1; }
echo "The cucumberswift commands ran from the checkout."
