#!/usr/bin/env bash
# cleanup.sh - R5 snapshot/stash-restore of dirty trees. S3-IMPL R5 (AC5.1-5.3).
# Universal factory tooling; no BANXE-domain logic.
#
# Before a task touches a target tree, snapshot any dirty state (AC5.1). On
# completion, restore the original state (AC5.2). Idempotent; out-of-scope
# work is preserved, never discarded (AC5.3). This addresses OBS/F: parallel
# sessions must never lose a human's uncommitted out-of-scope work.
#
# Usage:
#   cleanup.sh snapshot <tree>  -> stash dirty state, print stash ref or NONE
#   cleanup.sh restore  <tree>  -> pop the engine snapshot if present
# Env: DRY_RUN=1 (plan only).
set -euo pipefail
DRY_RUN="${DRY_RUN:-0}"
STASH_MSG="orchestrator-cleanup-snapshot"
log() { printf '[cleanup] %s\n' "$*" >&2; }
is_dirty() { [ -n "$(git -C "$1" status --porcelain --untracked-files=all)" ]; }
find_stash() { git -C "$1" stash list 2>/dev/null | grep -F "$STASH_MSG" | head -n1 | cut -d: -f1; }
snapshot() {
  local tree="$1"
  [ -d "$tree" ] || { log "snapshot: no tree $tree"; exit 1; }
  if [ "$DRY_RUN" = "1" ]; then
    if is_dirty "$tree"; then log "DRY_RUN: would stash dirty tree $tree"; else log "DRY_RUN: tree clean, no snapshot"; fi
    printf 'NONE\n'; return 0
  fi
  # AC5.1: snapshot only if dirty. Include untracked so out-of-scope files survive.
  if is_dirty "$tree"; then
    git -C "$tree" stash push --include-untracked -m "$STASH_MSG" >&2
    log "SNAPSHOT taken for $tree"
    find_stash "$tree"
  else
    log "tree clean, no snapshot needed: $tree"
    printf 'NONE\n'
  fi
}
restore() {
  local tree="$1"
  [ -d "$tree" ] || { log "restore: no tree $tree"; exit 1; }
  if [ "$DRY_RUN" = "1" ]; then
    log "DRY_RUN: would restore snapshot for $tree (if any)"
    return 0
  fi
  # AC5.2/AC5.3: restore original state; idempotent (noop if no snapshot).
  local ref; ref="$(find_stash "$tree")"
  if [ -n "$ref" ]; then
    git -C "$tree" stash pop "$ref" >&2
    log "RESTORED snapshot $ref for $tree"
  else
    log "restore: no engine snapshot present (idempotent noop): $tree"
  fi
}
cmd="${1:-}"; shift || true
case "$cmd" in
  snapshot) snapshot "$@";;
  restore) restore "$@";;
  *) log "usage: cleanup.sh {snapshot <tree>|restore <tree>}"; exit 2;;
esac
