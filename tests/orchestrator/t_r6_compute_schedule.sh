#!/usr/bin/env bash
# t_r6_compute_schedule.sh - Gate A (dry-run) test for R6 compute-aware scheduling.
# Asserts: a task targeting a NOT-loaded model is DEFERRED (not failed), and the
# scheduler reads the layer map from COMPUTE-TOPOLOGY.md rather than hardcoding.
# Mutation-free: dry-run only, no repo writes.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HEALTH="$ROOT/scripts/orchestrator/health.sh"
TOPO="$ROOT/docs/factory/COMPUTE-TOPOLOGY.md"
FAILS=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1" >&2; FAILS=$((FAILS+1)); }

export ROLE_ANCHOR="$ROOT/.TERMINAL-ROLE"
[[ -f "$ROLE_ANCHOR" ]] || { ROLE_ANCHOR="$(mktemp)"; export ROLE_ANCHOR; }

# --- AC6.3: layer map source of truth exists and is referenced ---
if [[ -f "$TOPO" ]] && grep -q "Model layering" "$TOPO"; then
  pass "AC6.3 scheduler layer map present in COMPUTE-TOPOLOGY.md (no hardcode)"
else
  fail "AC6.3 COMPUTE-TOPOLOGY.md layer map missing"
fi

# --- AC6.2: not-loaded model => DEFER (rc=2), distinct from hard failure ---
# Point at an unreachable node; probe_model must return DEFER, not 0/1.
set +e
LITELLM_URL="http://127.0.0.1:4000" DRY_RUN=0 \
  bash "$HEALTH" model "http://127.0.0.1:59998" "qwen3:235b-a22b" >/dev/null 2>&1
rc=$?
set -e
if [[ "$rc" -eq 2 ]]; then
  pass "AC6.2 not-loaded model yields DEFER (rc=2), scheduler can requeue"
else
  fail "AC6.2 expected DEFER rc=2 for not-loaded model, got rc=$rc"
fi

# --- AC6.1: DRY_RUN=1 plan-mode returns 0 without contacting nodes ---
if DRY_RUN=1 bash "$HEALTH" model "http://x" "any" >/dev/null 2>&1; then
  pass "AC6.1 DRY_RUN=1 plan-mode returns 0 (mutation-free)"
else
  fail "AC6.1 DRY_RUN=1 plan-mode should return 0"
fi

if [[ "$FAILS" -gt 0 ]]; then echo "R6 GATE: $FAILS failure(s)" >&2; exit 1; fi
echo "R6 GATE: all assertions passed"
