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

  # 7. OVERRIDES.md exists with ≥31 override definitions
  test -f docs/canon/OVERRIDES.md || rc=1
  if [ -f docs/canon/OVERRIDES.md ]; then
    local ov_count
    ov_count=$(grep -c '^## !' docs/canon/OVERRIDES.md 2>/dev/null || true)
    [ "$ov_count" -ge 31 ] || rc=1
  fi

  # 8. MODULES.md exists with ≥6 module definitions
  test -f docs/canon/MODULES.md || rc=1
  if [ -f docs/canon/MODULES.md ]; then
    local mod_total mod_meta mod_effective
    mod_total=$(grep -c '^## ' docs/canon/MODULES.md 2>/dev/null || true)
    mod_meta=$(grep -cE '^## (Format|Common|Forbidden|Anchoring|Combination)' docs/canon/MODULES.md 2>/dev/null || true)
    mod_effective=$((mod_total - mod_meta))
    [ "$mod_effective" -ge 6 ] || rc=1
  fi

  # 9. PATTERNS.md exists and is non-empty
  test -f docs/canon/PATTERNS.md || rc=1
  test -s docs/canon/PATTERNS.md 2>/dev/null || rc=1

  # 10. CANON-TRACE.md exists and references both integration sources
  test -f docs/canon/CANON-TRACE.md || rc=1
  if [ -f docs/canon/CANON-TRACE.md ]; then
    grep -q "CORE v4.11.1" docs/canon/CANON-TRACE.md 2>/dev/null || rc=1
    grep -q "Universalnyi v4.15.1" docs/canon/CANON-TRACE.md 2>/dev/null || rc=1
  fi

  # 11. CANON-TOPOLOGY.md version matches CANON.md
  if [ -f docs/canon/CANON-TOPOLOGY.md ]; then
    local ver_canon ver_topo
    ver_canon=$(grep -m1 '^Canon version: ' CANON.md 2>/dev/null | sed 's/^Canon version: //')
    ver_topo=$(grep -m1 '^Canon version: ' docs/canon/CANON-TOPOLOGY.md 2>/dev/null | sed 's/^Canon version: //')
    [ "$ver_canon" = "$ver_topo" ] || rc=1
  fi

  # 12. CANON-AUDIT-REPORT.md freshness
  if [ -f docs/canon/CANON-AUDIT-REPORT.md ]; then
    local ver_canon_fr
    ver_canon_fr=$(grep -m1 '^Canon version: ' CANON.md 2>/dev/null | sed 's/^Canon version: //')
    grep -q "Canon version: ${ver_canon_fr}" docs/canon/CANON-AUDIT-REPORT.md 2>/dev/null || rc=1
  fi

  # 13. Controlled extensions anchored to v1.3+
  for f in .claude/agents/canon-guardian.md quality-core/.claude/agents/factory-watchdog.md; do
    [ -f "$f" ] || rc=1
    if [ -f "$f" ]; then
      grep -qE "CANON\.md v1\.[3-9]|CANON\.md v[2-9]" "$f" 2>/dev/null || rc=1
    fi
  done

  # 14. Forbidden overrides mirrored in OVERRIDES.md
  if [ -f CANON.md ] && [ -f docs/canon/OVERRIDES.md ]; then
    local forbidden_cmds
    forbidden_cmds=$(awk '/^Forbidden modifiers:/{flag=1} flag && /!/{print; next} flag && /^$/{flag=0}' CANON.md | grep -oE '![a-z][a-z-]+' | sort -u)
    for cmd in $forbidden_cmds; do
      grep -q "$cmd" docs/canon/OVERRIDES.md 2>/dev/null || rc=1
    done
  fi

  # 15. Forbidden modules mirrored in MODULES.md
  if [ -f CANON.md ] && [ -f docs/canon/MODULES.md ]; then
    local forbidden_line forbidden_mods
    forbidden_line=$(grep -m1 '^Forbidden modules:' CANON.md 2>/dev/null)
    forbidden_mods=$(echo "$forbidden_line" | sed 's/^Forbidden modules://' | tr ',' '\n' | sed 's/[. ]//g' | sort -u | grep -v '^$')
    for mod in $forbidden_mods; do
      grep -qi "$mod" docs/canon/MODULES.md 2>/dev/null || rc=1
    done
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
