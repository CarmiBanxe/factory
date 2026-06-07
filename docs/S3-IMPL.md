# S3-IMPL — Factory Orchestration Engine (R1–R7)

Implementation anchor for the Orchestration Requirements defined in CANON.md (commit 69d6228). This document is the single source of truth that the engine implementation must satisfy. Authoring of the engine code happens in a local clone of this branch; this spec pins components, paths, and acceptance criteria.

R1–R5 are the resource-conflict engine. R6–R7 extend the engine to be compute-topology-aware (R6) and model-gateway health-gated (R7), per COMPUTE-TOPOLOGY.md.

## Scope and classification

- Schedulable (this engine resolves): resource conflicts (repo/branch/scope contention) and compute-resource contention (R6).
- Not schedulable (out of scope): semantic decisions (TS<->Python correspondence, coverage policy, broken tests/PSD2, webhook contracts). These require merit-based human resolution and MUST NOT be auto-resolved by the scheduler.

## Components and target paths

- scripts/orchestrator/queue.sh — R1 task queue intake (build-request submission).
- scripts/orchestrator/worktree.sh — R2 ephemeral worktree/clone lifecycle + in-scope staging.
- scripts/orchestrator/lock.sh — R3 repo+branch lock/lease manager.
- scripts/orchestrator/scheduler.sh — R4 serialize-conflicting / parallelize-independent + R6 compute-aware placement.
- scripts/orchestrator/cleanup.sh — R5 snapshot/stash-restore of dirty trees.
- scripts/orchestrator/health.sh — R7 model-gateway health probe (read-only, fail-closed).
- config/orchestrator.queue.tsv — persisted queue state (task_id, repo, branch, scope, status, lease_owner, ts).
- docs/COMPUTE-TOPOLOGY.md — canonical compute topology (hosts/capacity/gateway) read by R6/R7.

## Requirements -> acceptance criteria

### R1. Task queue

Central and B submit build-requests to the factory queue rather than running claude -p directly in a shared bash.

- AC1.1: enqueue writes a task row (task_id, repo, branch, scope, status=queued) to config/orchestrator.queue.tsv.
- AC1.2: no task executes claude -p outside a worktree allocated by the engine.
- AC1.3: queue intake is idempotent on duplicate task_id.

### R2. Per-task isolation

Tasks run in ephemeral worktrees/clones created automatically; only in-scope paths are staged.

- AC2.1: each task gets a fresh git worktree under .orchestrator/worktrees/.
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

### R6. Compute-aware scheduling

The scheduler is aware of the real compute topology (COMPUTE-TOPOLOGY.md) and never over-commits a host beyond its declared capacity.

- AC6.1: max-parallel per host is derived from COMPUTE-TOPOLOGY.md capacity, not a single global constant.
- AC6.2: a task whose compute placement would exceed host capacity stays status=queued and waits; it MUST NOT fail.
- AC6.3: placement is deterministic in DRY_RUN=1 and produces a plan without launching any work or mutating repos.

### R7. Model-gateway health gate

Agent runs that require a model MUST pass through the gateway, and the gateway health is checked before an expensive run is admitted.

- AC7.1: health.sh probes the gateway read-only and reports healthy/unhealthy; it never calls a model directly.
- AC7.2: when the gateway is unhealthy the scheduler holds the task (status=queued) rather than failing or bypassing the gateway.
- AC7.3: health.sh is fail-closed on a missing .TERMINAL-ROLE anchor (exit non-zero, no silent skip) consistent with F6.

## Gate alignment

- Gate A (dry-run) MUST precede Gate B: scheduler supports DRY_RUN=1 producing a plan without mutating repos, including R6 placement and R7 health admission.
- Canon Guardian (Axiom consistency + factory/project separation) must stay green; the engine is universal factory tooling and MUST NOT embed BANXE-domain logic.
- Per-task worktrees (R2) are the canonical isolation boundary, guarded by worktree path, not file scope alone.
- R7 health and R6 placement are read-only in Gate A: no model is called and no host is mutated during the dry-run plan.

## Test plan (tests/orchestrator/)

- t_r1_queue.sh: enqueue/idempotency/no-direct-claude.
- t_r2_worktree.sh: isolation + in-scope staging + teardown.
- t_r3_lock.sh: lease atomicity, wait-not-fail, TTL expiry.
- t_r4_schedule.sh: serialize-on-conflict, parallelize-on-disjoint, max-parallel.
- t_r5_cleanup.sh: stash-on-dirty, restore, idempotency.
- t_r6_compute_schedule.sh: per-host capacity cap, over-capacity waits (not fail), deterministic DRY_RUN plan.
- t_r7_gateway_gate.sh: unhealthy-gateway holds task, no direct model call, fail-closed on missing role anchor.
- t_p3_preflight.sh: Gate A preflight (F2 output_type/scope fail-fast, OBS5 self-sufficiency, F3 --sync-base ff-only plan-only in DRY_RUN).

## Out of scope for this PR

- Downstream rollout (rollout-canon-to-repo.sh) and mirror distribution are handled separately after the engine lands and is green.

## Central production feedback (6/6 CONTRACT layer session)

Source: Central produced all 6 ports (Wallet/Partner/Exchange/KYC/Notification/CRM; PR #5/#7/#8/#146/#149/#150) + ADR-045 through the factory. Below are consumer observations; implementation is Terminal A's zone (engine/agents). Each item maps to a factory requirement.

### Priority ranking (best-solution order)

- P1: per-task worktree + branch lock (root class of session collisions) -> R2 + R3. Maps to obs #1.
- P2: robust SPEC name recognizer (cheap fix, removes a class of false FAIL) -> F1.
- P3: early output_type/scope check before expensive run -> F2 + A2. Maps to obs #2/#8, #5.

### CRITICAL

- OBS1 Orchestration/worktree (root of session conflicts): parallel-session twice hijacked git checkout during SPEC translation; foreign .claude/memory/commit-log.jsonl blocked rebase; foreign INDEX broke checkout. parallel-session-isolation fired (good) but it is a symptom of a shared working tree. REQ: task queue (R1) + per-task isolated worktree/clone (R2) + branch lock (R3) instead of shared bash tree; auto-clean dirty trees (R5).
- OBS2 Auto coverage-omit for contract-only ports (recurred every repo): each new ABC port without tests dropped overall coverage <80%. Fixed omit manually twice (payment-core #9, emi-stack #147). First time omit went into .coveragerc but CI reads pyproject [tool.coverage] -> lost a cycle. REQ: when producing a contract port the engine itself checks/adds the omit pattern (*_provider_port.py / *_port.py) into the CORRECT coverage config of the target repo (detect pyproject [tool.coverage] vs .coveragerc).

### IMPORTANT

- OBS3 developer agent did not run ruff format (recurred 2x): wallet and partner failed CI ruff format --check; agent ran ruff check but not format. REQ: developer MUST run both ruff format AND ruff check --fix over allowed_scope at the end.
- OBS4 TS->Python normalization needed a manual step every port: all 6 SPECs were TypeScript, target Python. developer agent CAN translate (proven on kyc). REQ: build in TS->Python normalization (developer or a pipeline step) so no manual translate tasks.
- OBS5 SPEC-completeness not checked before architect: CRMPort failed architect NOT READY (types deferred to parent SPEC #6). architect stopped correctly but the expensive pipeline already ran. REQ: pre-flight SPEC self-sufficiency check (types/signatures present) BEFORE STAGE 1; bonus: architect pulls types from parent-SPEC by reference instead of failing.

### USEFUL

- OBS6 local main vs origin desync blocked a run: NotificationPort SPEC was in origin/main but not local main (diverged 12/3); REAL reads SPEC from local main. Pre-flight warns (good). REQ: engine option --sync-base (ff-only fetch+update target main before prepare_target_branch).
- OBS7 spec-repo-map config drift/incomplete: typo scope src/exchangport/** (missing e); missing notification row; tests/ in scope for contract-code (wrong). REQ: spec-repo-map validator (paths match target repo, output_type consistency, contract-code -> only src/ no tests) before run.
- OBS8 git add -A in STAGE 5 (ALREADY FIXED, PR #20): selective staging shipped. Closed; noted for completeness.

### Factory engine improvements (spec-build.sh)

- F1 SPEC name recognizer is fragile: infer_spec_family requires exact glob exchangeportcontractspec and fails on hyphenated exchange-port -> lost iterations. REQ: normalize basename before matching (strip hyphens/case) OR match on the Family: field inside the SPEC, not the filename.
- F2 output_type<->SPEC content mismatch caught late (STAGE 1): SPEC required impl (3 adapters) but family configured contract-code; architect rejected only at STAGE 1, after Gate A/STAGE 0. REQ: early check on Gate A (SPEC declares impl artifacts but output=contract-code) before agents run.
- F3 no base auto-sync: WARN local main diverges from origin (NOT auto-fixed) twice. REQ: --sync-base (ff-only) so PR base is not dirty. (Same as OBS6.)
- F4 --spec-ref only in dry-run; real reads only from main. Forced a commit->push->PR->merge chain for a doc-only rename before the factory could run. Keep as guard (real from main is auditable) but DOCUMENT this flow explicitly.
- F5 worktree/branch discipline unprotected: main session failure was the branch switching under us to adr-046, our SPEC went to stash. REQ: per-task isolated worktree + branch lock (R2+R3).
- F6 role-guard silently skipped: WARN no .TERMINAL-ROLE anchor - skipping. A guard that skips on missing anchor does not protect. REQ: fail-closed (or explicit warn-with-exit-code), not silent skip.

### AI agent improvements

- architect: give a verdict earlier and cheaper (light pre-architect SPEC lint on Gate A). Maps to OBS5/F2.
- developer: + mandatory ruff format (OBS3), + coverage-omit awareness (OBS2), + built-in TS->Python (OBS4). Run scope-check in dry-run too (statically from SPEC declarations) to catch out-of-scope before real.
- SPEC-authoring agent must NOT switch branches: it did checkout adr-046 and stashed our file. REQ: content-author agent works strictly inside its allocated worktree, no branch switches without explicit mandate.
- accept-edits auto mode nearly committed outside stepwise control. REQ: for factory tasks use propose-diff/no-auto-commit; commit only via a controlled step.
- reviewer / canon-guardian: worked without issues (correct verdicts every time). DO NOT TOUCH.
