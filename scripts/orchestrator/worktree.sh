#!/usr/bin/env bash
# worktree.sh — R2 ephemeral per-task worktree lifecycle + in-scope staging.
# S3-IMPL R2 (AC2.1-2.3). Universal factory tooling; no BANXE-domain logic.
#
# The per-task worktree is the canonical isolation boundary (S3-IMPL Gate
# alignment): isolation is guarded by worktree PATH, not file scope alone.
# This directly addresses OBS1/F5 (shared bash tree hijacked by parallel
# sessions; branch switched under a running task).
#
# Usage:
#   worktree.sh create <task_id> <branch>            -> prints worktree path
#   worktree.sh stage  <task_id> <scope_glob> [more]  -> stage only in-scope paths
#   worktree.sh remove <task_id>                      -> teardown (success or fail)
# Env: ORCH_WT_DIR (default .orchestrator/worktrees), DRY_RUN=1 (plan only).
set -euo pipefail

WT_BASE="${ORCH_WT_DIR:-.orchestrator/worktrees}"
DRY_RUN="${DRY_RUN:-0}"

log() { printf '[worktree] %s\n' "$*" >&2; }
slug() { printf '%s' "$1" | tr '/:@ ' '____'; }
wt_path() { printf '%s/%s' "$WT_BASE" "$(slug "$1")"; }

root() { git rev-parse --show-toplevel 2>/dev/null || { log "not a git repo"; exit 1; }; }

create() {
  local task_id="$1" branch="$2" path
  path="$(wt_path "$task_id")"
  if [ "$DRY_RUN" = "1" ]; then
    log "DRY_RUN: would create worktree $path for task=$task_id branch=$branch"
    printf '%s\n' "$path"
    return 0
  fi
  mkdir -p "$WT_BASE"
  # Fresh worktree per task (AC2.1). Reuse is forbidden: remove a stale one first.
  if [ -d "$path" ]; then
    log "stale worktree present, tearing down first: $path"
    remove "$task_id"
  fi
  # Detach onto branch tip in an isolated checkout; create branch if absent.
  if git show-ref --verify --quiet "refs/heads/$branch"; then
    git worktree add "$path" "$branch" >&2
  else
    git worktree add -b "$branch" "$path" >&2
  fi
  log "CREATED worktree $path (task=$task_id branch=$branch)"
  printf '%s\n' "$path"
}

stage() {
  # AC2.2: staging restricted to scope globs; out-of-scope dirty files never added.
  local task_id="$1"; shift
  local path; path="$(wt_path "$task_id")"
  [ -d "$path" ] || { log "stage: no worktree for task=$task_id"; return 1; }
  [ "$#" -ge 1 ] || { log "stage: at least one scope glob required"; return 2; }
  local g added=0
  for g in "$@"; do
    if [ "$DRY_RUN" = "1" ]; then
      log "DRY_RUN: would 'git add -- $g' within $path"
      continue
    fi
    # pathspec add is bounded to the worktree; globs limit to in-scope paths only.
    if git -C "$path" add -- $g 2>/dev/null; then
      added=1
    fi
  done
  if [ "$DRY_RUN" != "1" ] && [ "$added" = "1" ]; then
    log "STAGED in-scope paths for task=$task_id: $*"
    git -C "$path" diff --cached --name-only >&2 || true
  fi
}

remove() {
  # AC2.3: worktree removed on completion (success or fail); idempotent.
  local task_id="$1" path
  path="$(wt_path "$task_id")"
  if [ "$DRY_RUN" = "1" ]; then
    log "DRY_RUN: would remove worktree $path"
    return 0
  fi
  if [ -d "$path" ]; then
    git worktree remove --force "$path" 2>/dev/null || rm -rf "$path"
    log "REMOVED worktree $path (task=$task_id)"
  else
    log "remove: no worktree for task=$task_id (noop)"
  fi
  git worktree prune 2>/dev/null || true
}

root >/dev/null
cmd="${1:-}"; shift || true
case "$cmd" in
  create) create "$@";;
  stage)  stage "$@";;
  remove) remove "$@";;
  *) log "usage: worktree.sh {create|stage|remove} ..."; exit 2;;
esac
