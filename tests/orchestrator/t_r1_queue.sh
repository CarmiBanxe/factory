#!/usr/bin/env bash
# t_r1_queue.sh - Gate A tests for scripts/orchestrator/queue.sh (S3-IMPL R1).
# Covers AC1.1 enqueue writes a task row, AC1.2 intake only (no execution),
# AC1.3 idempotent on duplicate task_id. Plus DRY_RUN plan-only (Gate A).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
Q="$HERE/../../scripts/orchestrator/queue.sh"
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
export ORCH_QUEUE="config/orchestrator.queue.tsv"
QF="$REPO/$ORCH_QUEUE"
# DRY_RUN (Gate A): plan only, writes no queue file.
( cd "$REPO" && DRY_RUN=1 bash "$Q" enqueue task-001 repoA feat/x 'src/*.py' ) >/dev/null 2>&1
if [ ! -f "$QF" ]; then ok "Gate A DRY_RUN plan-only (no queue file written)"; else bad "DRY_RUN should not write queue"; fi
# AC1.1: enqueue writes a task row into config/orchestrator.queue.tsv.
( cd "$REPO" && bash "$Q" enqueue task-001 repoA feat/x 'src/*.py' ) >/dev/null 2>&1
if [ -f "$QF" ] && grep -q '^task-001' "$QF"; then ok "AC1.1 enqueue writes task row"; else bad "AC1.1 task row not written"; fi
# AC1.2: intake only - no execution side effects (no worktree dir created).
if [ ! -d "$REPO/.orchestrator/worktrees" ]; then ok "AC1.2 intake only (no execution outside worktrees)"; else bad "AC1.2 unexpected execution"; fi
# AC1.3: idempotent on duplicate task_id - row count stays 1.
( cd "$REPO" && bash "$Q" enqueue task-001 repoA feat/x 'src/*.py' ) >/dev/null 2>&1
n="$(grep -c '^task-001' "$QF")"
if [ "$n" = "1" ]; then ok "AC1.3 idempotent on duplicate task_id"; else bad "AC1.3 duplicate row (n=$n)"; fi
# A distinct task_id still appends.
( cd "$REPO" && bash "$Q" enqueue task-002 repoB feat/y 'lib/*.ts' ) >/dev/null 2>&1
if grep -q '^task-002' "$QF"; then ok "distinct task_id appended"; else bad "distinct task_id not appended"; fi
printf '\n[t_r1_queue] pass=%s fail=%s\n' "$pass" "$fail"
[ "$fail" = "0" ]
