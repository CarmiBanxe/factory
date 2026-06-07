# S3-IMPL — Factory Orchestration Engine (R1–R5)

Implementation anchor for the Orchestration Requirements defined in CANON.md (commit 69d6228). This document is the single source of truth that the engine implementation must satisfy. Authoring of the engine code happens in a local clone of this branch; this spec pins components, paths, and acceptance criteria.

## Scope and classification

- Schedulable (this engine resolves): resource conflicts (repo/branch/scope contention).
- Not schedulable (out of scope): semantic decisions (TS<->Python correspondence, coverage policy, broken tests/PSD2, webhook contracts). These require merit-based human resolution and MUST NOT be auto-resolved by the scheduler.

## Components and target paths

- scripts/orchestrator/queue.sh — R1 task queue intake (build-request submission).
- scripts/orchestrator/worktree.sh — R2 ephemeral worktree/clone lifecycle + in-scope staging.
- scripts/orchestrator/lock.sh — R3 repo+branch lock/lease manager.
- scripts/orchestrator/scheduler.sh — R4 serialize-conflicting / parallelize-independent.
- scripts/orchestrator/cleanup.sh — R5 snapshot/stash-restore of dirty trees.
- config/orchestrator.queue.tsv — persisted queue state (task_id, repo, branch, scope, status, lease_owner, ts).

## Requirements -> acceptance criteria

### R1. Task queue
Central and B submit build-requests to the factory queue rather than running claude -p directly in a shared bash.
- AC1.1: enqueue writes a task row (task_id, repo, branch, scope, status=queued) to config/orchestrator.queue.tsv.
- AC1.2: no task executes claude -p outside a worktree allocated by the engine.
- AC1.3: queue intake is idempotent on duplicate task_id.

### R2. Per-task isolation
Tasks run in ephemeral worktrees/clones created automatically; only in-scope paths are staged.
- AC2.1: each task gets a fresh git worktree under .orchestrator/worktrees/<task_id>.
- AC2.2: staging is restricted to the task scope globs; out-of-scope dirty files are never added.
- AC2.3: worktree is removed on task completion (success or fail).

### R3. Lock/lease by resource
Repo+branch locks ensure conflicting tasks wait in the queue rather than failing.
- AC3.1: a lease key is repo+branch; acquiring is atomic.
- AC3.2: a task that cannot acquire its lease stays status=queued and retries; it MUST NOT fail.
- AC3.3: leases expire (TTL) so a crashed task does not deadlock the queue.

### R4. Serialization / Parallelization
Conflicting tasks (same repo/scope) are serialized; independent tasks are parallelized.
- AC4.1: tasks sharing repo+branch or overlapping scope run strictly serially.
- AC4.2: tasks with disjoint repo/scope run concurrently up to a configurable max-parallel.
- AC4.3: scope overlap is computed from the scope globs, consistent with config/spec-repo-map.tsv.

### R5. Auto-cleanup
Automatic snapshot/stash-restore of dirty trees before a run.
- AC5.1: before a run the target tree is snapshotted (stash) if dirty.
- AC5.2: on completion the original tree state is restored.
- AC5.3: cleanup is safe to re-run (idempotent) and never discards out-of-scope user work silently.

## Gate alignment

- Gate A (dry-run) MUST precede Gate B: scheduler supports DRY_RUN=1 producing a plan without mutating repos.
- Canon Guardian (Axiom consistency + factory/project separation) must stay green; the engine is universal factory tooling and MUST NOT embed BANXE-domain logic.
- Per-task worktrees (R2) are the canonical isolation boundary, guarded by worktree path, not file scope alone.

## Test plan (tests/orchestrator/)

- t_r1_queue.sh: enqueue/idempotency/no-direct-claude.
- t_r2_worktree.sh: isolation + in-scope staging + teardown.
- t_r3_lock.sh: lease atomicity, wait-not-fail, TTL expiry.
- t_r4_schedule.sh: serialize-on-conflict, parallelize-on-disjoint, max-parallel.
- t_r5_cleanup.sh: stash-on-dirty, restore, idempotency.

## Out of scope for this PR

- Downstream rollout (rollout-canon-to-repo.sh) and mirror distribution are handled separately after the engine lands and is green.
