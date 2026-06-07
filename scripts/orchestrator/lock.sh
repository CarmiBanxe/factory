#!/usr/bin/env bash
# lock.sh — R3 repo+branch lock/lease manager (S3-IMPL R3, AC3.1-3.3).
# Universal factory tooling. No BANXE-domain logic (Canon Guardian: factory/project separation).
#
# Lease key = repo+branch. Acquire is atomic (mkdir). Callers that cannot
# acquire MUST stay queued and retry (wait-not-fail). Leases carry a TTL so a
# crashed task cannot deadlock the queue.
#
# Usage:
#   lock.sh acquire <repo> <branch> <owner> [ttl_seconds]   -> 0 acquired / 10 busy
#   lock.sh release <repo> <branch> <owner>                 -> 0 released
#   lock.sh status  <repo> <branch>                         -> prints owner/expiry or 'free'
#   lock.sh reap    [base_dir]                              -> remove expired leases (idempotent)
# Env: ORCH_LOCK_DIR (default .orchestrator/locks), DRY_RUN=1 (plan only, no mutation).
set -euo pipefail

LOCK_DIR="${ORCH_LOCK_DIR:-.orchestrator/locks}"
DRY_RUN="${DRY_RUN:-0}"
DEFAULT_TTL="${ORCH_LEASE_TTL:-900}"

log() { printf '[lock] %s\n' "$*" >&2; }

# Lease key is repo+branch, filesystem-safe.
key() { printf '%s' "$1__$2" | tr '/:@ ' '____'; }
now() { date +%s; }

lease_path() { printf '%s/%s.lease' "$LOCK_DIR" "$(key "$1" "$2")"; }

_expired() {
  # $1 = lease dir; echo 1 if expired/absent, 0 if still valid
  local d="$1" exp
  [ -d "$d" ] || { echo 1; return; }
  exp="$(cat "$d/expires_at" 2>/dev/null || echo 0)"
  if [ "$(now)" -ge "$exp" ]; then echo 1; else echo 0; fi
}

reap() {
  local base="${1:-$LOCK_DIR}"
  [ -d "$base" ] || return 0
  local d
  for d in "$base"/*.lease; do
    [ -e "$d" ] || continue
    if [ "$(_expired "$d")" = "1" ]; then
      log "reaping expired lease: $(basename "$d")"
      [ "$DRY_RUN" = "1" ] || rm -rf "$d"
    fi
  done
}

acquire() {
  local repo="$1" branch="$2" owner="$3" ttl="${4:-$DEFAULT_TTL}"
  local d; d="$(lease_path "$repo" "$branch")"
  reap "$LOCK_DIR"
  if [ "$DRY_RUN" = "1" ]; then
    log "DRY_RUN: would acquire $repo@$branch for $owner (ttl=${ttl}s)"
    return 0
  fi
  mkdir -p "$LOCK_DIR"
  # Atomic acquire: mkdir succeeds for exactly one contender.
  if mkdir "$d" 2>/dev/null; then
    printf '%s' "$owner" > "$d/owner"
    printf '%s' "$(( $(now) + ttl ))" > "$d/expires_at"
    log "ACQUIRED $repo@$branch by $owner (ttl=${ttl}s)"
    return 0
  fi
  # Held: re-entrant for same owner, else busy (wait-not-fail -> exit 10).
  if [ "$(cat "$d/owner" 2>/dev/null)" = "$owner" ]; then
    printf '%s' "$(( $(now) + ttl ))" > "$d/expires_at"
    log "RE-HELD $repo@$branch by $owner (lease renewed)"
    return 0
  fi
  log "BUSY $repo@$branch held by $(cat "$d/owner" 2>/dev/null || echo '?') — caller must stay queued and retry"
  return 10
}

release() {
  local repo="$1" branch="$2" owner="$3"
  local d; d="$(lease_path "$repo" "$branch")"
  [ -d "$d" ] || { log "release: no lease for $repo@$branch (noop)"; return 0; }
  if [ "$(cat "$d/owner" 2>/dev/null)" != "$owner" ]; then
    log "release: $owner is not lease owner of $repo@$branch — refusing"
    return 11
  fi
  [ "$DRY_RUN" = "1" ] || rm -rf "$d"
  log "RELEASED $repo@$branch by $owner"
}

status() {
  local repo="$1" branch="$2"
  local d; d="$(lease_path "$repo" "$branch")"
  if [ "$(_expired "$d")" = "1" ]; then echo "free"; return 0; fi
  printf 'held owner=%s expires_at=%s\n' "$(cat "$d/owner")" "$(cat "$d/expires_at")"
}

cmd="${1:-}"; shift || true
case "$cmd" in
  acquire) acquire "$@";;
  release) release "$@";;
  status)  status "$@";;
  reap)    reap "$@";;
  *) log "usage: lock.sh {acquire|release|status|reap} ..."; exit 2;;
esac
