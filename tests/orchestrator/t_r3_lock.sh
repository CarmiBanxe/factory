#!/usr/bin/env bash
# t_r3_lock.sh — Gate A tests for scripts/orchestrator/lock.sh (S3-IMPL R3).
# Covers AC3.1 atomic acquire, AC3.2 wait-not-fail, AC3.3 TTL expiry + reap.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
LOCK="$HERE/../../scripts/orchestrator/lock.sh"
TMP="$(mktemp -d)"
export ORCH_LOCK_DIR="$TMP/locks"
trap 'rm -rf "$TMP"' EXIT

pass=0; fail=0
ok()   { printf 'ok   - %s\n' "$1"; pass=$((pass+1)); }
bad()  { printf 'FAIL - %s\n' "$1"; fail=$((fail+1)); }

# AC3.1: first acquire succeeds (exit 0).
bash "$LOCK" acquire repoX main owner1 300
if [ "$?" = "0" ]; then ok "AC3.1 acquire is atomic/succeeds"; else bad "AC3.1 acquire"; fi

# AC3.2: a different owner cannot acquire -> exit 10 (busy), MUST NOT fail (not 1).
bash "$LOCK" acquire repoX main owner2 300
rc=$?
if [ "$rc" = "10" ]; then ok "AC3.2 busy returns 10 (wait-not-fail)"; else bad "AC3.2 expected 10 got $rc"; fi

# Same owner is re-entrant (renew) -> exit 0.
bash "$LOCK" acquire repoX main owner1 300
if [ "$?" = "0" ]; then ok "AC3.2 re-entrant for same owner"; else bad "AC3.2 re-entrant"; fi

# status reports held.
if bash "$LOCK" status repoX main | grep -q '^held'; then ok "status held"; else bad "status held"; fi

# AC3.3: TTL expiry -> reap frees the lease; status becomes free.
bash "$LOCK" acquire repoY dev owner3 1
sleep 2
bash "$LOCK" reap "$ORCH_LOCK_DIR"
if bash "$LOCK" status repoY dev | grep -q '^free'; then ok "AC3.3 expired lease reaped"; else bad "AC3.3 TTL reap"; fi

# reap is idempotent (safe to re-run).
bash "$LOCK" reap "$ORCH_LOCK_DIR"
if [ "$?" = "0" ]; then ok "reap idempotent"; else bad "reap idempotent"; fi

# release by owner frees the lease.
bash "$LOCK" release repoX main owner1
if bash "$LOCK" status repoX main | grep -q '^free'; then ok "release frees lease"; else bad "release"; fi

printf '\n[t_r3_lock] pass=%s fail=%s\n' "$pass" "$fail"
[ "$fail" = "0" ]
