#!/usr/bin/env bash
# queue.sh - R1 task queue intake. S3-IMPL R1 (AC1.1-1.3).
# Universal factory tooling; no BANXE-domain logic.
#
# Enqueue a task row into config/orchestrator.queue.tsv. Tasks are NEVER
# executed here and NEVER outside engine-allocated worktrees (AC1.2): this
# is intake only. Duplicate task_id is idempotent (AC1.3).
#
# Usage:
#   queue.sh enqueue <task_id> <repo> <branch> <scope_glob>
#   queue.sh list
# Env: ORCH_QUEUE (default config/orchestrator.queue.tsv), DRY_RUN=1 (plan only).
set -euo pipefail
QUEUE="${ORCH_QUEUE:-config/orchestrator.queue.tsv}"
DRY_RUN="${DRY_RUN:-0}"
log() { printf '[queue] %s\n' "$*" >&2; }
root() { git rev-parse --show-toplevel >/dev/null 2>&1 || { log "not a git repo"; exit 1; }; }
ensure() { [ -f "$QUEUE" ] || { mkdir -p "$(dirname "$QUEUE")"; printf 'task_id\trepo\tbranch\tscope\tstate\n' > "$QUEUE"; }; }
has_task() { [ -f "$QUEUE" ] && awk -F'\t' -v id="$1" 'NR>1 && $1==id {found=1} END{exit !found}' "$QUEUE"; }
enqueue() {
  local task_id="$1" repo="$2" branch="$3" scope="$4"
  if [ "$DRY_RUN" = "1" ]; then
    log "DRY_RUN: would enqueue task=$task_id repo=$repo branch=$branch scope=$scope into $QUEUE"
    return 0
  fi
  ensure
  # AC1.3: idempotent on duplicate task_id - never append a second row.
  if has_task "$task_id"; then
    log "task already queued (idempotent noop): $task_id"
    return 0
  fi
  # AC1.1: enqueue writes a task row. AC1.2: state=queued; execution is
  # deferred to the scheduler inside an allocated worktree, never here.
  printf '%s\t%s\t%s\t%s\t%s\n' "$task_id" "$repo" "$branch" "$scope" "queued" >> "$QUEUE"
  log "ENQUEUED task=$task_id (state=queued)"
}
list() { ensure; cat "$QUEUE"; }
root
cmd="${1:-}"; shift || true
case "$cmd" in
  enqueue) enqueue "$@";;
  list) list "$@";;
  *) log "usage: queue.sh {enqueue <task_id> <repo> <branch> <scope>|list}"; exit 2;;
esac
