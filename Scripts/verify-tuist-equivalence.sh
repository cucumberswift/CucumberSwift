#!/bin/bash
#
# verify-tuist-equivalence.sh
#
# Checks that the Tuist manifest reproduces the committed CucumberSwift.xcodeproj
# closely enough for every consumer, including Carthage. macOS only: it needs
# Xcode and Tuist.
#
# Run it from the repository root:
#
#     ./Scripts/verify-tuist-equivalence.sh
#
# It regenerates the project in place. The committed copy is saved first and
# restored at the end, so the working tree is left as it was found.

set -euo pipefail

PROJECT="CucumberSwift.xcodeproj"
SCHEME_DIR="$PROJECT/xcshareddata/xcschemes"
CARTHAGE_SCHEME="$SCHEME_DIR/CucumberSwift.xcscheme"
DESTINATION='platform=macOS,variant=Mac Catalyst'
BACKUP="$(mktemp -d)/committed-project"

step() { printf '\n==> %s\n' "$1"; }
fail() { printf '\nFAILED: %s\n' "$1" >&2; exit 1; }

[ -d "$PROJECT" ] || fail "run this from the repository root"
command -v tuist >/dev/null || fail "tuist not on PATH (try: mise install)"
command -v xcodebuild >/dev/null || fail "xcodebuild not on PATH"

step "Saving the committed project"
mkdir -p "$(dirname "$BACKUP")"
cp -R "$PROJECT" "$BACKUP"
restore() {
    rm -rf "$PROJECT"
    cp -R "$BACKUP" "$PROJECT"
}
trap restore EXIT

step "Recording the committed project's schemes"
xcodebuild -list -project "$PROJECT" > /tmp/schemes-committed.txt
cat /tmp/schemes-committed.txt

step "Generating with Tuist"
rm -rf "$PROJECT"
tuist generate --no-open

# ---------------------------------------------------------------------------
# Carthage depends on both of these. A generated project whose scheme is not
# SHARED is invisible to Carthage, and the project file alone is not enough.
# ---------------------------------------------------------------------------

step "Checking the Carthage scheme is shared"
[ -f "$CARTHAGE_SCHEME" ] \
    || fail "$CARTHAGE_SCHEME missing. Carthage only builds shared schemes."
echo "found $CARTHAGE_SCHEME"

step "Checking no scheme landed in xcuserdata instead"
if find "$PROJECT/xcuserdata" -name '*.xcscheme' 2>/dev/null | grep -q .; then
    find "$PROJECT/xcuserdata" -name '*.xcscheme'
    fail "schemes in xcuserdata are per-user and invisible to Carthage"
fi
echo "none, good"

step "Comparing scheme lists"
xcodebuild -list -project "$PROJECT" > /tmp/schemes-generated.txt
if diff -u /tmp/schemes-committed.txt /tmp/schemes-generated.txt; then
    echo "identical"
else
    fail "scheme list changed. fastlane and Carthage both key off these names."
fi

step "Building the CucumberSwift scheme (the one Carthage uses)"
xcodebuild build \
    -scheme CucumberSwift \
    -destination "$DESTINATION" \
    CODE_SIGNING_ALLOWED=NO

step "Running the test suite (baseline: 190 tests, 0 failures, 3 skipped)"
xcodebuild test \
    -scheme CucumberSwift \
    -destination "$DESTINATION" \
    CODE_SIGNING_ALLOWED=NO

# Optional. Carthage's own README recommends this as the way to confirm a
# dependency's schemes are discoverable.
if command -v carthage >/dev/null; then
    step "Carthage discovery check"
    carthage build --no-skip-current --platform iOS
else
    printf '\n==> Carthage not installed, skipping discovery check\n'
fi

step "All checks passed"
echo "The committed project has been restored."
