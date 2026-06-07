#!/usr/bin/env bash
# t_r5_cleanup.sh - Gate A tests for scripts/orchestrator/cleanup.sh (S3-IMPL R5).
# Covers AC5.1 snapshot dirty tree, AC5.2 restore on completion, AC5.3
# idempotent + preserves out-of-scope work. Plus DRY_RUN plan-only (Gate A).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
C="$HERE/../../scripts/orchestrator/cleanup.sh"
pass=0; fail=0
ok() { printf 'ok - %s\n' "$1"; pass=$((pass+1)); }
bad() { printf 'FAIL - %s\n' "$1"; fail=$((fail+1)); }
# Throwaway repo so the test never touches the real factory tree.
REPO="$(mktemp -d)"
trap 'rm -rf "$REPO"' EXIT
git -C "$REPO" init -q
git -C "$REPO" config user.email t@t.local
git -C "$REPO" config user.name t
printf 'seed\n' > "$REPO/seed.txt"
git -C "$REPO" add seed.txt
git -C "$REPO" commit -qm seed
# Dirty the tree with an out-of-scope uncommitted change (human's work).
printf 'human-wip\n' > "$REPO/out_of_scope.txt"
# DRY_RUN (Gate A): plan only, leaves the dirty file in place (no stash).
DRY_RUN=1 bash "$C" snapshot "$REPO" >/dev/null 2>&1
if [ -f "$REPO/out_of_scope.txt" ] && [ -z "$(git -C "$REPO" stash list)" ]; then ok "Gate A DRY_RUN plan-only (no stash, file untouched)"; else bad "DRY_RUN should not stash"; fi
# AC5.1: snapshot a dirty tree (real) -> stash created, working tree clean.
bash "$C" snapshot "$REPO" >/dev/null 2>&1
if [ -n "$(git -C "$REPO" stash list)" ] && [ ! -f "$REPO/out_of_scope.txt" ]; then ok "AC5.1 dirty tree snapshotted (stashed)"; else bad "AC5.1 snapshot did not stash dirty tree"; fi
# AC5.2/AC5.3: restore brings back the original out-of-scope work intact.
bash "$C" restore "$REPO" >/dev/null 2>&1
if [ -f "$REPO/out_of_scope.txt" ] && grep -q 'human-wip' "$REPO/out_of_scope.txt"; then ok "AC5.2 original out-of-scope work restored"; else bad "AC5.2 restore lost out-of-scope work"; fi
if [ -z "$(git -C "$REPO" stash list)" ]; then ok "AC5.3 snapshot consumed on restore"; else bad "AC5.3 stash left behind"; fi
# AC5.3: restore is idempotent (noop when no snapshot present).
bash "$C" restore "$REPO" >/dev/null 2>&1
if [ "$?" = "0" ] && [ -f "$REPO/out_of_scope.txt" ]; then ok "AC5.3 restore idempotent (noop preserves work)"; else bad "AC5.3 restore not idempotent"; fi
# snapshot on a clean tree is a noop (no stash).
git -C "$REPO" add -A && git -C "$REPO" commit -qm wip >/dev/null 2>&1
bash "$C" snapshot "$REPO" >/dev/null 2>&1
if [ -z "$(git -C "$REPO" stash list)" ]; then ok "clean tree snapshot is noop"; else bad "clean tree should not stash"; fi
printf '\n[t_r5_cleanup] pass=%s fail=%s\n' "$pass" "$fail"
[ "$fail" = "0" ]
