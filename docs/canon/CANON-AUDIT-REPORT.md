# Canon Audit Report — Factory Governance

**Date:** 2026-06-07 (version-sync to v1.7; Sprints 1-5 enforcement)
Canon version: 1.6.1 (target 1.7 — sync in progress; CANON.md not yet bumped)
**Scope:** `/home/mmber/factory/` (factory-level only, no bank repos)
**Method:** Full read of all canon-bearing files (~95 KB) + Sprint 3-5 orchestration engine artifacts (R1-R5)

---

## 1. Inventory of Canon-Bearing Files

| # | Path | Size | Type |
|---|------|------|------|
| 1 | `factory/CANON.md` | ~5K | Axiom + Extensions v1.2 + Honest Reporting v1.3 |
| 2 | `factory/docs/factory/FACTORY-CANON-ADDENDUM-TERMINAL-B-AUTONOMY-2026-05-12.md` | 1.6K | Operational addendum |
| 3 | `factory/.claude/settings.local.json` | 574 B | Permission config |
| 4 | `factory/banxe-repo-template/README.md` | 1.3K | Template doc |
| 5 | `factory/banxe-repo-template/.claude/settings.json` | 708 B | Template config |
| 6 | `factory/banxe-repo-template/.github/workflows/claude.yml` | 378 B | Template workflow |
| 7 | `factory/banxe-repo-template/.github/workflows/factory-guard.yml` | 388 B | Template guard |
| 8 | `factory/banxe-repo-template/.github/workflows/guardian.yml` | 4.6K | Remote audit |
| 9 | `factory/quality-core/.claude/agents/factory-watchdog.md` | 16K | Enforcement agent |
| 10 | `factory/quality-core/semgrep/fintech-rules.yml` | 8.3K | Code rules |
| 11 | `factory/quality-core/workflows/quality-gate.yml` | 7.4K | CI template |
| 12 | `factory/quality-core/workflows/lint-python.yml` | 2.2K | CI template |
| 13 | `factory/ui-sync-core/.claude/agents/ui-sync.md` | 3.0K | Generation agent |
| 14 | `factory/ui-sync-core/.claude/skills/lazyweb-research.md` | 6.7K | Research skill |
| 15 | `factory/ui-sync-core/tokens/tokens.example.json` | 4.1K | Token format sample |
| 16 | `factory/p1-summary.md` | 23K | Implementation guide |
| 17 | `factory/rollout-v2-report.md` | 2.3K | Deployment log |
| 18 | `factory/docs/S3-IMPL.md` | ~11K | Orchestration engine spec (R1-R5) |
| 19 | `factory/docs/factory/COMPUTE-TOPOLOGY.md` | — | Compute topology (hosts/capacity/gateway) — informational, not bound to canon R-set |
| 20 | `factory/scripts/orchestrator/*` + `factory/tests/orchestrator/*` | — | Engine impl + Gate A tests (R1-R5) |

## 2. Classification Table

| File | Factory governance | Bank-mirror | Mixed | Obsolete |
|------|-------------------|-------------|-------|----------|
| CANON.md | **primary** | — | — | — |
| Terminal-B-Autonomy | **primary** | — | — | — |
| settings.local.json | **primary** | — | — | — |
| banxe-repo-template/* (5 files) | **primary** | — | — | — |
| factory-watchdog.md | **primary** | — | — | — |
| fintech-rules.yml | **primary** | — | — | — |
| quality-gate.yml | **primary** | — | — | — |
| lint-python.yml | **primary** | — | — | — |
| ui-sync.md | **primary** | — | — | — |
| lazyweb-research.md | **primary** | — | — | — |
| tokens.example.json | **primary** | — | — | — |
| rollout-v2-report.md | **primary** | — | — | — |
| S3-IMPL.md + orchestrator engine (R1-R7) | **primary** | — | — | — |
| COMPUTE-TOPOLOGY.md | **primary** | — | — | — |
| p1-summary.md | — | — | **mixed** | — |

**Result:** All factory-governance files are internally consistent. The orchestration engine (R1-R7) is universal factory tooling and embeds no BANXE-domain logic. 1 file (`p1-summary.md`) remains mixed (frozen, see Weak Point #2).

## 3. Conflict Map

**No conflicts detected between any files.** All files are internally consistent. The Decision-Making Axiom in CANON.md is respected or explicitly restated in every agent spec and operational doc. No file contradicts another.

**Intentional duplications (acceptable):**

| Axiom copy | Location | Reason |
|---|---|---|
| Verbatim | banxe-repo-template/README.md | Template must be self-contained |
| Verbatim | Terminal-B-Autonomy addendum | Terminal B scope clarity |
| Verbatim | factory-watchdog.md | Agent operational scope |
| Paraphrase (Russian) | settings.json template | Agent runtime instruction |

## 4. Strong Points

1. **Single axiom source** — CANON.md is unambiguous and short (5 rules, 510 bytes).
2. **Enforcement chain complete** — Axiom → watchdog agent → semgrep rules → CI workflows → PR guard → remote guardian. No gap in enforcement path.
3. **Factory/project separation clean** — factory owns templates and rules; repos consume via controlled copies with drift detection.
4. **UI parity discipline layered** — ui-sync (generation) + lazyweb-research (advisory) + watchdog Mode 4 (enforcement). Three layers, no overlap, clear boundaries.
5. **Token source project-defined** — token source is project-defined (TOKEN_SOURCE); factory ships `tokens.example.json` as a format sample. style-dictionary generates platform outputs from the configured source.
6. **Orchestration engine canonized (R1-R7)** — resource-conflict (R1-R5) + compute-aware (R6) + gateway health-gate (R7); Gate A dry-run precedes Gate B; per-task worktree isolation; fail-closed role guard.

## 5. Weak Points

1. ~~**No dedicated canon-enforcement agent.**~~ **RESOLVED v1.0** — `factory/.claude/agents/canon-guardian.md` created with 4 modes.
2. ~~**`p1-summary.md` is mixed.**~~ **RESOLVED v1.3** — bank-specifics frozen at `docs/history/p1-summary-bank.md`; factory-level patterns migrated into `docs/canon/PATTERNS.md`.
3. ~~**No canon versioning.**~~ **RESOLVED v1.0** — CANON.md carries a version header.
4. ~~**No canon diff policy.**~~ **RESOLVED v1.0** — CANON-TOPOLOGY.md §4 defines change procedure.
5. ~~**`style-dictionary.config.js` not in audit scope of any agent.**~~ **RESOLVED v1.7** — factory-watchdog Mode 3 check #8 now carries explicit JS-config drift logic: SHA256 of `style-dictionary.config.js` (or `.mjs`) vs factory canonical AND output `tokens.json` hash vs last build; JS-config drift is HIGH severity even if output coincidentally matches. (Prior YELLOW was a stale audit note; the verification logic was already present.)
6. ~~**Orchestration engine not in audit inventory.**~~ **RESOLVED v1.7** — S3-IMPL.md (R1-R7), COMPUTE-TOPOLOGY.md, and scripts/tests orchestrator added to inventory §1 and topology hierarchy.

## 6. Recommendations (status)

1. ~~Create `canon-guardian.md`.~~ Done.
2. ~~Create `CANON-TOPOLOGY.md`.~~ Done.
3. ~~Add version/date header to CANON.md.~~ Done.
4. ~~Split `p1-summary.md`.~~ Done.
5. ~~Define canon diff propagation procedure.~~ Done (CANON-TOPOLOGY §4).
6. **Next (Sprint 7+):** R8 = engine observability / execution audit-trail (structured Gate A plan logs + per-host metrics, read-only, no mutation).

## 7. Orchestration Engine Status (R1-R7)

| Req | Capability | State |
|---|---|---|
| R1 | Task queue intake | GREEN (impl + t_r1_queue.sh) |
| R2 | Per-task worktree isolation | GREEN (impl + t_r2_worktree.sh) |
| R3 | Repo+branch lock/lease | GREEN (impl + t_r3_lock.sh) |
| R4 | Serialize/parallelize | GREEN (impl + t_r4_schedule.sh) |
| R5 | Auto-cleanup (stash/restore) | GREEN (impl + t_r5_cleanup.sh) |
| R6 | Compute-aware scheduling | GREEN (scheduler + t_r6_compute_schedule.sh; reads COMPUTE-TOPOLOGY.md) |
| R7 | Model-gateway health gate | GREEN (health.sh + t_r7_gateway_gate.sh; fail-closed on missing .TERMINAL-ROLE) |

Gate discipline: Gate A (DRY_RUN dry-run, no main mutation) precedes Gate B merge; Canon Guardian must be green before Gate B. All R1-R7 landed via this discipline.
