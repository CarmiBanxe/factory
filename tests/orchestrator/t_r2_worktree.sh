#!/usr/bin/env bash
# t_r2_worktree.sh — Gate A tests for scripts/orchestrator/worktree.sh (S3-IMPL R2).
# Covers AC2.1 fresh worktree under .orchestrator/worktrees/, AC2.2 in-scope-only
# staging, AC2.3 teardown. Plus DRY_RUN plan-only behaviour (Gate A).
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
WT="$HERE/../../scripts/orchestrator/worktree.sh"

pass=0; fail=0
ok()  { printf 'ok   - %s\n' "$1"; pass=$((pass+1)); }
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

export ORCH_WT_DIR=".orchestrator/worktrees"
TASK=task-001; BRANCH=feat/iso-test

# DRY_RUN (Gate A): plan only, prints a path, mutates nothing.
out="$(cd "$REPO" && DRY_RUN=1 bash "$WT" create "$TASK" "$BRANCH")"
if [ -n "$out" ] && [ ! -d "$REPO/$ORCH_WT_DIR/$TASK" ]; then ok "Gate A DRY_RUN plan-only (no worktree created)"; else bad "DRY_RUN should not create worktree"; fi

# AC2.1: real create makes a fresh worktree under .orchestrator/worktrees/.
wtp="$(cd "$REPO" && bash "$WT" create "$TASK" "$BRANCH")"
if [ -d "$wtp" ] && printf '%s' "$wtp" | grep -q '.orchestrator/worktrees/'; then ok "AC2.1 fresh worktree under .orchestrator/worktrees/"; else bad "AC2.1 worktree path"; fi

# Create one in-scope and one out-of-scope dirty file inside the worktree.
mkdir -p "$wtp/src"
printf 'in\n'  > "$wtp/src/in_scope.py"
printf 'out\n' > "$wtp/secret_out_of_scope.txt"

# AC2.2: stage only the scope glob; out-of-scope file must NOT be staged.
( cd "$REPO" && bash "$WT" stage "$TASK" 'src/*.py' ) >/dev/null 2>&1
staged="$(git -C "$wtp" diff --cached --name-only)"
if printf '%s' "$staged" | grep -q 'src/in_scope.py'; then ok "AC2.2 in-scope file staged"; else bad "AC2.2 in-scope not staged"; fi
if printf '%s' "$staged" | grep -q 'secret_out_of_scope.txt'; then bad "AC2.2 out-of-scope LEAKED into staging"; else ok "AC2.2 out-of-scope file never added"; fi

# AC2.3: teardown removes the worktree; idempotent re-run is safe.
( cd "$REPO" && bash "$WT" remove "$TASK" ) >/dev/null 2>&1
if [ ! -d "$wtp" ]; then ok "AC2.3 worktree removed on completion"; else bad "AC2.3 teardown"; fi
( cd "$REPO" && bash "$WT" remove "$TASK" ) >/dev/null 2>&1
if [ "$?" = "0" ]; then ok "AC2.3 remove idempotent"; else bad "AC2.3 remove idempotent"; fi

printf '\n[t_r2_worktree] pass=%s fail=%s\n' "$pass" "$fail"
[ "$fail" = "0" ]
