#!/usr/bin/env bash
# t_r4_schedule.sh - Gate A tests for scripts/orchestrator/scheduler.sh (S3-IMPL R4).
# Covers AC4.1 same repo+branch or overlapping scope -> serial, AC4.2 disjoint
# repo/scope -> parallel, AC4.3 scope overlap computed from globs.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
S="$HERE/../../scripts/orchestrator/scheduler.sh"
pass=0; fail=0
ok() { printf 'ok - %s\n' "$1"; pass=$((pass+1)); }
bad() { printf 'FAIL - %s\n' "$1"; fail=$((fail+1)); }
# conflict exits 0 when tasks must serialize, 1 when independent.
conf() { bash "$S" conflict "$@" >/dev/null 2>&1; }
# AC4.1: same repo + same branch -> serialize.
if conf repoA feat/x 'src/*.py' repoA feat/x 'lib/*.py'; then ok "AC4.1 same repo+branch serialized"; else bad "AC4.1 same repo+branch should serialize"; fi
# AC4.1/AC4.3: same repo, overlapping scope globs -> serialize.
if conf repoA feat/x 'src/*.py' repoA feat/y 'src/api.py'; then ok "AC4.3 overlapping scope serialized"; else bad "AC4.3 overlapping scope should serialize"; fi
# AC4.2: disjoint repos -> parallel (independent).
if conf repoA feat/x 'src/*.py' repoB feat/x 'src/*.py'; then bad "AC4.2 disjoint repos should be parallel"; else ok "AC4.2 disjoint repos run concurrently"; fi
# AC4.2/AC4.3: same repo, non-overlapping scope -> parallel.
if conf repoA feat/x 'src/*.py' repoA feat/y 'docs/*.md'; then bad "AC4.2 disjoint scope should be parallel"; else ok "AC4.2 disjoint scope runs concurrently"; fi
# plan over a queue file classifies pairs.
Q="$(mktemp)"
trap 'rm -f "$Q"' EXIT
printf 'task_id\trepo\tbranch\tscope\tstate\n' > "$Q"
printf 't1\trepoA\tfeat/x\tsrc/*.py\tqueued\n' >> "$Q"
printf 't2\trepoA\tfeat/x\tlib/*.py\tqueued\n' >> "$Q"
printf 't3\trepoB\tfeat/z\tdocs/*.md\tqueued\n' >> "$Q"
out="$(bash "$S" plan "$Q" 2>/dev/null)"
if printf '%s' "$out" | grep -q '^serial'; then ok "plan emits serial pair for conflict"; else bad "plan missing serial pair"; fi
if printf '%s' "$out" | grep -q '^parallel'; then ok "plan emits parallel pair for independent"; else bad "plan missing parallel pair"; fi
printf '\n[t_r4_schedule] pass=%s fail=%s\n' "$pass" "$fail"
[ "$fail" = "0" ]
