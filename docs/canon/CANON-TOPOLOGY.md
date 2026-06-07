Canon version: 1.7
Date: 2026-06-07

# Canon Topology — Factory Governance Structure

**Date:** 2026-06-07
**Authority:** `factory/CANON.md` v1.7 (Decision-Making Axiom + Extensions + Honest Reporting + enforcement Sprints 1-7)

---

## 1. Canon Hierarchy

```
factory/CANON.md                                      ← LEVEL 0: foundational axiom
├── factory/docs/canon/CANON-TOPOLOGY.md              ← LEVEL 1: governance structure (this file)
├── factory/docs/canon/CANON-AUDIT-REPORT.md          ← LEVEL 1: audit findings
│
├── ENFORCEMENT AGENTS (LEVEL 2)
│   ├── factory/.claude/agents/canon-guardian.md      ← canon document consistency
│   ├── factory/quality-core/.claude/agents/factory-watchdog.md   ← quality + UI enforcement
│   └── factory/ui-sync-core/.claude/agents/ui-sync.md            ← generation orchestration
│
├── OPERATIONAL RULES (LEVEL 2)
│   ├── factory/docs/factory/FACTORY-CANON-ADDENDUM-TERMINAL-B-AUTONOMY-2026-05-12.md
│   └── factory/ui-sync-core/.claude/skills/lazyweb-research.md
│
├── ORCHESTRATION ENGINE (LEVEL 2, Sprints 3-7, R1-R7)
│   ├── factory/docs/S3-IMPL.md                       ← engine spec (R1-R7 acceptance criteria)
│   ├── factory/docs/factory/COMPUTE-TOPOLOGY.md      ← compute topology (hosts/capacity/gateway), read by R6/R7
│   └── factory/scripts/orchestrator/                 ← queue/worktree/lock/scheduler/cleanup/health (R1-R7)
│
├── DISTRIBUTION TEMPLATE (LEVEL 3)
│   ├── factory/banxe-repo-template/README.md
│   ├── factory/banxe-repo-template/.claude/settings.json
│   └── factory/banxe-repo-template/.github/workflows/{claude,factory-guard,guardian}.yml
│
├── ENFORCEMENT ARTIFACTS (LEVEL 3)
│   ├── factory/quality-core/semgrep/fintech-rules.yml
│   ├── factory/quality-core/workflows/quality-gate.yml
│   ├── factory/quality-core/workflows/lint-python.yml
│   ├── factory/ui-sync-core/tokens/tokens.example.json
│   ├── factory/ui-sync-core/tokens/style-dictionary.config.js
│   └── factory/ui-sync-core/proto-sync.py
│
└── OPERATIONAL RECORDS (LEVEL 4, read-only reference)
    ├── factory/p1-summary.md
    └── factory/rollout-v2-report.md
```

## 2. Source vs Copy Policy

| Category | Definition | Update rule |
|---|---|---|
| **Source** | Authoritative version. Changes originate here. | Edit directly. Canon-guardian verifies copies after. |
| **Controlled copy** | Intentional verbatim or paraphrase in another file. | Never edit copy directly. Update source, then propagate. |
| **Repo mirror** | Copy distributed to bank repos via template bootstrap. | Updated by re-running factory adapter or rollout script. |
| **Generated** | Produced by a factory tool (style-dictionary, proto-sync). | Never edit. Regenerate from source. |

### Decision-Making Axiom copies

| Location | Type | Propagation |
|---|---|---|
| `factory/CANON.md` | **source** | — |
| `factory/banxe-repo-template/README.md` §Canon | controlled copy | canon-guardian detects drift |
| `factory/docs/factory/*-AUTONOMY-*.md` §Axiom alignment | controlled copy | canon-guardian detects drift |
| `factory/quality-core/.claude/agents/factory-watchdog.md` §Axiom | controlled copy | canon-guardian detects drift |
| `factory/banxe-repo-template/.claude/settings.json` canon field | paraphrase (Russian) | manual review on CANON.md change |

### Enforcement artifact sources

| Artifact | Source | Copies in repos |
|---|---|---|
| `fintech-rules.yml` | `factory/quality-core/semgrep/` | Downloaded at CI runtime (no local copy) |
| `quality-gate.yml` | `factory/quality-core/workflows/` | Controlled copy in `.github/workflows/` |
| `lint-python.yml` | `factory/quality-core/workflows/` | Controlled copy in `.github/workflows/` |
| `tokens.example.json` | `factory/ui-sync-core/tokens/` | Format sample; project defines its own token source via TOKEN_SOURCE (controlled copy in `config/design-tokens/`) |
| `proto-sync.py` | `factory/ui-sync-core/` | Controlled copy in `scripts/` |
| `style-dictionary.config.js` | `factory/ui-sync-core/tokens/` | Controlled copy in `config/design-tokens/` |

## 3. Factory vs Bank-Project Responsibility Split

| Responsibility | Owner | Location |
|---|---|---|
| Decision-Making Axiom | Factory | `factory/CANON.md` |
| Canon topology and audit | Factory | `factory/docs/canon/` |
| Orchestration engine spec + compute topology | Factory | `factory/docs/S3-IMPL.md`, `factory/docs/factory/COMPUTE-TOPOLOGY.md` |
| Quality rules (semgrep, ruff base) | Factory | `factory/quality-core/` |
| UI generation and parity rules | Factory | `factory/ui-sync-core/` |
| CI workflow templates | Factory | `factory/quality-core/workflows/` |
| Agent specs (watchdog, ui-sync, canon-guardian) | Factory | `factory/*/.claude/agents/` |
| Repo-local overrides (`repo-overrides.yaml`) | Bank-project | Each repo root |
| Repo-local adapter config (paths, thresholds) | Bank-project | Each repo |
| Service-specific semgrep rules (DB tables, etc.) | Bank-project | Each repo `.semgrep/` |
| Generated component output | Bank-project | Each repo `apps/` |
| Business logic, ADRs, invariants | Bank-project | Each repo `docs/` |

## 4. Canon Change Procedure

When `factory/CANON.md` is modified:
1. Canon-guardian agent detects the change (Mode 1: source-change detection).
2. Canon-guardian identifies all controlled copies via this topology.
3. Canon-guardian proposes exactly one update (highest-priority copy first).
4. After approval, propagate to next copy.
5. After all copies updated, canon-guardian runs drift verification (Mode 2).
6. Bank-project repo mirrors updated via next factory adapter rollout.

## 5. Canon Versioning

`factory/CANON.md` must carry a version header:
```
Canon version: X.Y
Date: YYYY-MM-DD
```
- Major (X): axiom added or removed.
- Minor (Y): wording clarification, copy propagation, or topology change.

Current version: **1.7** (2026-06-07, enforcement Sprints 1-7; adds orchestration engine R1-R7 + compute topology).
