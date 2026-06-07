#!/usr/bin/env bash
# terminal-role-guard.sh — blocks commits that violate three-terminal canon.
# Reads .TERMINAL-ROLE in repo root; checks staged paths against role.
set -euo pipefail
root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
anchor="$root/.TERMINAL-ROLE"
[ -f "$anchor" ] || { echo "[role-guard] WARN: no .TERMINAL-ROLE anchor — skipping"; exit 0; }
role="$(grep -oiE 'Terminal (A|Central|B)' "$anchor" | head -1)"
staged="$(git diff --cached --name-only)"
[ -z "$staged" ] && exit 0
viol=""
case "$role" in
  *A*)  # factory only — forbid committing BANXE product service code
    echo "$staged" | grep -qiE '(^|/)services/.*\.py$' && viol="Terminal A must NOT commit BANXE product code (services/*.py)";;
  *Central*) # BANXE code — forbid editing factory internals
    echo "$staged" | grep -qiE '(^|/)(spec-build\.sh|quality-core/|ui-sync-core/|role-anchors/|CANON\.md)$|spec-repo-map\.tsv' && viol="Terminal Central must NOT modify factory internals (A's zone)";;
  *B*) echo "$staged" | grep -qiE '(^|/)(spec-build\.sh|quality-core/|ui-sync-core/)' && viol="Terminal B must NOT modify factory internals (A's zone)";;
esac
if [ -n "$viol" ]; then
  echo "[role-guard] BLOCKED ($role): $viol"
  echo "[role-guard] Если это намеренно — закоммитьте с --no-verify и зафиксируйте отклонение от канона."
  exit 1
fi
echo "[role-guard] OK ($role)"
