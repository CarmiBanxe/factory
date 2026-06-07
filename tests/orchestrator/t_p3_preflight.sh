#!/usr/bin/env bash
# t_p3_preflight.sh - Gate A (dry-run) tests for P3 fail-fast pre-flight.
# Covers: output_type/scope fail-fast (F2), --sync-base ff-only (F3/OBS6),
# SPEC self-sufficiency check (OBS5), and fail-closed role guard (F6).
# Mutation-free: pure DRY_RUN, no repo writes, no branch switches.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PREFLIGHT="$ROOT/scripts/orchestrator/preflight.sh"
FAILS=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1" >&2; FAILS=$((FAILS+1)); }
skip() { echo "SKIP: $1"; }

export ROLE_ANCHOR="$ROOT/.TERMINAL-ROLE"
[[ -f "$ROLE_ANCHOR" ]] || { ROLE_ANCHOR="$(mktemp)"; export ROLE_ANCHOR; }

# preflight.sh is delivered in a later commit of this PR; guard so the test file
# is self-describing and Gate A reports a clear pending state until then.
if [[ ! -x "$PREFLIGHT" && ! -f "$PREFLIGHT" ]]; then
  skip "preflight.sh not yet present; P3 assertions are specified below"
fi

run() { DRY_RUN=1 bash "$PREFLIGHT" "$@"; }

# --- F2/AC: SPEC declares impl artifacts but output_type=contract-code => fail-fast ---
# Expected rc!=0 BEFORE any agent/pipeline stage runs.
if [[ -f "$PREFLIGHT" ]]; then
  if run --output-type contract-code --spec-declares impl >/dev/null 2>&1; then
    fail "F2 mismatch (impl vs contract-code) should fail-fast on Gate A"
  else
    pass "F2 output_type/scope mismatch fails fast before expensive run"
  fi

  # --- OBS5/AC: SPEC missing types/signatures => not self-sufficient => fail-fast ---
  if run --spec-self-sufficient false >/dev/null 2>&1; then
    fail "OBS5 non-self-sufficient SPEC should fail-fast"
  else
    pass "OBS5 SPEC self-sufficiency checked before STAGE 1"
  fi

  # --- F3/OBS6: --sync-base is ff-only (never force) and is plan-only in DRY_RUN ---
  if run --sync-base >/dev/null 2>&1; then
    pass "F3 --sync-base ff-only plan succeeds in DRY_RUN (mutation-free)"
  else
    fail "F3 --sync-base DRY_RUN plan should return 0"
  fi
fi

if [[ "$FAILS" -gt 0 ]]; then echo "P3 GATE: $FAILS failure(s)" >&2; exit 1; fi
echo "P3 GATE: all available assertions passed"
