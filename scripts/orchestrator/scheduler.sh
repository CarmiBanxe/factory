#!/usr/bin/env bash
# scheduler.sh - R4 conflict scheduler. S3-IMPL R4 (AC4.1-4.3).
# Universal factory tooling; no BANXE-domain logic.
#
# Serialize conflicting tasks, parallelize independent ones. Scheduling is
# SCHEDULABLE-only: resource conflicts (repo/branch/scope contention). It
# MUST NOT auto-resolve semantic decisions (out of scope, human merit).
#
# Two tasks CONFLICT when they share repo+branch, OR their scope globs
# overlap (AC4.1/AC4.3). Disjoint repo/scope tasks are independent (AC4.2).
#
# Usage:
#   scheduler.sh conflict <repoA> <branchA> <scopeA> <repoB> <branchB> <scopeB>
#       -> exit 0 if tasks conflict (serialize), 1 if independent (parallel).
#   scheduler.sh plan <queue.tsv>
#       -> prints 'serial <id> <id>' / 'parallel <id> <id>' for each pair.
set -euo pipefail
log() { printf '[scheduler] %s\n' "$*" >&2; }
# AC4.3: scope overlap computed from globs. Compare on glob prefix (dir before
# the first wildcard); identical or prefix-nested prefixes overlap.
glob_prefix() { printf '%s' "$1" | sed 's/[*?[].*$//'; }
scope_overlap() {
  local a b pa pb
  a="$1"; b="$2"
  pa="$(glob_prefix "$a")"; pb="$(glob_prefix "$b")"
  case "$pa" in "$pb"*) return 0;; esac
  case "$pb" in "$pa"*) return 0;; esac
  return 1
}
conflict() {
  local rA="$1" bA="$2" sA="$3" rB="$4" bB="$5" sB="$6"
  # AC4.1: same repo+branch => serialize.
  if [ "$rA" = "$rB" ] && [ "$bA" = "$bB" ]; then
    log "CONFLICT repo+branch shared: $rA@$bA"; return 0
  fi
  # AC4.1/AC4.3: same repo with overlapping scope => serialize.
  if [ "$rA" = "$rB" ] && scope_overlap "$sA" "$sB"; then
    log "CONFLICT scope overlap in $rA: $sA <> $sB"; return 0
  fi
  # AC4.2: disjoint repo or non-overlapping scope => independent.
  log "INDEPENDENT: ($rA,$bA,$sA) vs ($rB,$bB,$sB)"; return 1
}
plan() {
  local q="$1"
  [ -f "$q" ] || { log "plan: no queue file $q"; exit 1; }
  # Pairwise classification over queued rows (AC4.1/4.2).
  awk -F'\t' 'NR>1 && $5=="queued" {print $1"\t"$2"\t"$3"\t"$4}' "$q" > /tmp/.sched.$$ || true
  mapfile -t rows < /tmp/.sched.$$; rm -f /tmp/.sched.$$
  local i j
  for ((i=0; i<${#rows[@]}; i++)); do
    for ((j=i+1; j<${#rows[@]}; j++)); do
      IFS=$'\t' read -r idA rA bA sA <<< "${rows[$i]}"
      IFS=$'\t' read -r idB rB bB sB <<< "${rows[$j]}"
      if conflict "$rA" "$bA" "$sA" "$rB" "$bB" "$sB" 2>/dev/null; then
        printf 'serial\t%s\t%s\n' "$idA" "$idB"
      else
        printf 'parallel\t%s\t%s\n' "$idA" "$idB"
      fi
    done
  done
}
cmd="${1:-}"; shift || true
case "$cmd" in
  conflict) conflict "$@";;
  plan) plan "$@";;
  *) log "usage: scheduler.sh {conflict <rA> <bA> <sA> <rB> <bB> <sB>|plan <queue.tsv>}"; exit 2;;
esac
