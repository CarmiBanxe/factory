# OPEN GAPS — Factory Reality Ledger

**Status:** Living document. Updated whenever a gap is discovered, owned, or closed.
**Date opened:** 2026-06-07
**Maintainer:** Terminal A (factory) + Central (audit)
**Rule:** No gap closes silently. Closure requires a commit hash + evidence file.

---

## How to read this file

Every row is a real divergence between canon (declared) and production (observed). The audit `COMPUTE-AUDIT-2026-06-07.md` is the primary evidence base.

Status values: OPEN | IN-PROGRESS | BLOCKED | CLOSED
Priority: P0 (blocker) | P1 (critical) | P2 (hygiene)

---

## Active gaps

| # | Gap | Priority | Status | Owner | Evidence | Blocker / Note |
|---|---|---|---|---|---|---|
| G1 | LiteLLM gateway on Legion:4000 has no Postgres; all chat requests return No connected db. Canonical litellm-v2 user-service stopped since 2026-05-22. §1.bis single-seam routing is dead. | P0 | OPEN | Terminal A (infra) | COMPUTE-AUDIT-2026-06-07.md §4 | Needs shell on Legion. |
| G2 | Factory spec-build.sh calls claude -- (Anthropic), not local LLM. Local coder models idle. Strategic decision D1 required. | P0 | OPEN | User (strategic) | COMPUTE-AUDIT-2026-06-07.md §5 | Awaiting D1. |
| G3 | evo2 qwen3:235b (142GB) NOT loaded. AMD GPU/ROCm status unverified. | P0 | OPEN | Terminal A (infra) | COMPUTE-AUDIT-2026-06-07.md §3 | Needs ROCm repair. |
| G4 | Model role split violated: evo1 (declared infra) carries heavy models; evo2 (heavy) underused. | P1 | OPEN | Terminal A (infra) | COMPUTE-AUDIT-2026-06-07.md §2-3 | Migration plan needed. |
| G5 | ~200GB duplicated models across evo1/evo2. | P1 | OPEN | Terminal A (infra) | COMPUTE-AUDIT-2026-06-07.md §5C | Dedup after G4. |
| G6 | Stale HW Baseline (Legion 23 GiB declared vs 56 GB real). Source file of stale figure not yet located in canon tree. | P2 | OPEN | Comet (doc) | COMPUTE-AUDIT-2026-06-07.md §1 | Source-of-stale-figure must be found before edit. |
| G7 | CANON.md still v1.6.1 while branch is feat/canon-sync-v1.7. No concrete 1.6.1 -> 1.7 delta defined. | P1 | OPEN | User (strategic) | CANON-AUDIT-REPORT.md (d66eb49) | Awaiting D3. |
| G8 | S3-IMPL.md (R1-R5 spec) uncommitted in feat/s3-impl-engine-p3. | P1 | ON-HOLD | User | open editor tab | User placed on standby. |
| G9 | Orchestration Engine R1-R5 *.sh — spec only, no implementation. | P1 | OPEN | Terminal A (impl) | S3-IMPL.md AC1-AC5 | Blocked by G8. |
| G10 | No execution-protocol enforcement: tasks reported done while only partially executed (~15% last cycle). | P0 | IN-PROGRESS | Comet + Controller-Agent | EXECUTION-PROTOCOL.md | Solved in this canon update. |

---

## Closed gaps

| # | Gap | Closed by | Date |
|---|---|---|---|
| C1 | CANON-AUDIT-REPORT.md falsely declared R1-R7 and Canon version 1.7. | commit d66eb49 | 2026-06-07 |

---

## Update rules (canon binding)

1. Anyone discovering a gap MUST add a row here in the same commit that surfaces it.
2. A gap moves to CLOSED only with a commit hash + evidence link.
3. The Controller-Agent (EXECUTION-PROTOCOL.md) audits this file at the end of every task cycle.
4. If a task report claims completion but related gaps are still OPEN, the report is rejected.
