#!/usr/bin/env bash
# terminal-role-guard.sh — blocks commits that violate three-terminal canon.
# Reads .TERMINAL-ROLE in repo root; checks staged paths against role.
# FAIL-CLOSED: missing/unrecognized anchor blocks the commit (exit 1).
set -euo pipefail
root="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "[role-guard] BLOCKED: not a git repo"; exit 1; }
anchor="$root/.TERMINAL-ROLE"

# Explicit, logged bypass for bootstrap/CI only (never silent).
if [ "${ROLE_GUARD_BYPASS:-0}" = "1" ]; then
echo "[role-guard] BYPASS active (ROLE_GUARD_BYPASS=1) — canon check skipped explicitly"
exit 0
fi

if [ ! -f "$anchor" ]; then
echo "[role-guard] BLOCKED: no .TERMINAL-ROLE anchor at repo root ($anchor)"
echo "[role-guard] Fail-closed: create the anchor or set ROLE_GUARD_BYPASS=1 to override explicitly."
exit 1
fi

role="$(grep -oiE 'Terminal (A|Central|B)' "$anchor" | head -1)"
if [ -z "$role" ]; then
echo "[role-guard] BLOCKED: .TERMINAL-ROLE present but no recognizable role (expected Terminal A|Central|B)"
exit 1
fi

staged="$(git diff --cached --name-only)"
[ -z "$staged" ] && { echo "[role-guard] OK ($role): nothing staged"; exit 0; }
viol=""
case "$role" in
*A*) # factory only — forbid committing BANXE product service code
echo "$staged" | grep -qiE '(^|/)services/.*\.py$' && viol="Terminal A must NOT commit BANXE product code (services/*.py)";;
*Central*) # BANXE code — forbid editing factory internals
echo "$staged" | grep -qiE '(^|/)(spec-build\.sh|quality-core/|ui-sync-core/|role-anchors/|CANON\.md)$|spec-repo-map\.tsv' && viol="Terminal Central must NOT modify factory internals (A's zone)";;
*B*) echo "$staged" | grep -qiE '(^|/)(spec-build\.sh|quality-core/|ui-sync-core/)' && viol="Terminal B must NOT modify factory internals (A's zone)";;
*) echo "[role-guard] BLOCKED: unhandled role ($role)"; exit 1;;
esac
if [ -n "$viol" ]; then
echo "[role-guard] BLOCKED ($role): $viol"
echo "[role-guard] Если это намеренно — закоммитьте с --no-verify и зафиксируйте отклонение от канона."
exit 1
fi
echo "[role-guard] OK ($role)"
