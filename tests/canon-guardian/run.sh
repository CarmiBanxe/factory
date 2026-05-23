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

run_guardian_checks() {
  # Replicates the bash logic from .github/workflows/canon-guardian.yml.
  # Operates on the current working directory.
  local rc=0

  # 1. Verify CANON.md version header
  head -2 CANON.md 2>/dev/null | grep -q "^Canon version: " || rc=1
  head -2 CANON.md 2>/dev/null | grep -q "^Date: " || rc=1

  # 2. Verify .clauderules mirrors axiom rules 1-5
  for n in 1 2 3 4 5; do
    grep -q "^${n}\. " .clauderules 2>/dev/null || rc=1
    grep -q "^${n}\. " CANON.md 2>/dev/null || rc=1
  done

  # 3. Verify ADR-0001 exists and references CANON v1.2+
  test -f docs/adr/ADR-0001-decision-making-axiom.md || rc=1
  if [ -f docs/adr/ADR-0001-decision-making-axiom.md ]; then
    grep -qE "Canon version: 1\.[2-9]|Canon version: [2-9]" docs/adr/ADR-0001-decision-making-axiom.md || rc=1
  fi

  # 4. Forbid bank-project leaks in L0-L2 (excluding META-MENTION-OK lines)
  local PATTERN="banxe-payment-core|banxe-ui|banxe-infra|apps/web|apps/mobile|pnpm |npx expo"
  local FILES="CANON.md .clauderules docs/canon/CANON-TOPOLOGY.md docs/canon/PATTERNS.md docs/adr/ADR-0001-decision-making-axiom.md .claude/agents/canon-guardian.md"
  for f in $FILES; do
    [ -f "$f" ] || continue
    if grep -nE "$PATTERN" "$f" 2>/dev/null | grep -v "META-MENTION-OK" >/dev/null; then
      rc=1
    fi
  done

  # 5. Forbid legal-domain modifiers outside explicit exclusion blocks
  local LFILES="CANON.md .clauderules docs/canon/CANON-TOPOLOGY.md docs/canon/PATTERNS.md docs/adr/ADR-0001-decision-making-axiom.md .claude/agents/canon-guardian.md"
  for f in $LFILES; do
    [ -f "$f" ] || continue
    if grep -nE "!eucourt|!echrsearch|!cjeusearch|!ultralegal|!legalqa|ratio decidendi|dispositif|Plan 7|CURIA|HUDOC|EUR-Lex" "$f" 2>/dev/null >/dev/null; then
      if ! grep -nE "Forbidden modifiers|Forbidden modules|Non-legal scope|excluded from" "$f" 2>/dev/null >/dev/null; then
        rc=1
      fi
    fi
  done

  # 6. Verify axiom drift between CANON.md and .clauderules
  if [ -f CANON.md ] && [ -f .clauderules ]; then
    local axiom_canon axiom_rules
    axiom_canon=$(awk '/^## Decision-Making Axiom \(Canon\)/{flag=1; next} /^## /{flag=0} flag' CANON.md | sed -n '1,12p')
    axiom_rules=$(awk '/^## Decision-Making Axiom \(Canon\)/{flag=1; next} /^## /{flag=0} flag' .clauderules | sed -n '1,12p')
    [ "$axiom_canon" = "$axiom_rules" ] || rc=1
  fi

  return $rc
}

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
