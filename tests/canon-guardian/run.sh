#!/usr/bin/env bash
# Factory canon-guardian regression test runner.
# Anchored to CANON.md v1.3 §7 (RED-OPEN: canon-guardian regression tests).
#
# For each fixture under fixtures/NN-name/, applies the fixture's canon files
# into an isolated temp tree, runs the same checks as .github/workflows/canon-guardian.yml,
# and verifies that the result matches expected.txt (PASS or FAIL).

set -u
ROOT="$(cd "$(dirname "$0")" && pwd)"
FIX_DIR="$ROOT/fixtures"
PASS=0
FAIL=0
DETAILS=()

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-guardian-checks.sh
source "$SCRIPT_DIR/lib-guardian-checks.sh"


for fix in "$FIX_DIR"/*/; do
  [ -d "$fix" ] || continue
  name=$(basename "$fix")
  expected=$(cat "$fix/expected.txt" 2>/dev/null | tr -d '[:space:]')

  tmp=$(mktemp -d)
  # Copy fixture canon files into tmp (preserves directory structure under fixture)
  ( cd "$fix" && find . -type f ! -name expected.txt -print0 | tar --null -cf - --files-from=- ) | ( cd "$tmp" && tar -xf - )

  pushd "$tmp" >/dev/null
  if run_guardian_checks; then actual="PASS"; else actual="FAIL"; fi
  popd >/dev/null
  rm -rf "$tmp"

  if [ "$actual" = "$expected" ]; then
    PASS=$((PASS+1))
    DETAILS+=("OK   $name (expected $expected, got $actual)")
  else
    FAIL=$((FAIL+1))
    DETAILS+=("FAIL $name (expected $expected, got $actual)")
  fi
done

printf '%s\n' "${DETAILS[@]}"
echo "---"
echo "PASS: $PASS   FAIL: $FAIL"
[ "$FAIL" -eq 0 ]
