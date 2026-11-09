#!/bin/bash
# Checks what cucumberswift_lint and cucumberswift_generate wrote for CommandsFixture. $1 is the lint stamp and $2
# the generated tests.

set -euo pipefail

[[ "$(cat "$1")" == "0" ]] || { echo "FAIL: lint found $(cat "$1") problems in a clean feature file" >&2; exit 1; }
grep -q "Say hello" "$2" || { echo "FAIL: the generated tests do not name the scenario" >&2; exit 1; }
echo "PASS"
