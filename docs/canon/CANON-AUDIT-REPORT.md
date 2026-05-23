# Canon Audit Report — Factory Governance

**Date:** 2026-05-23
**Scope:** `/home/mmber/factory/` (factory-level only, no bank repos)
**Method:** Full read of all 17 canon-bearing files (~95 KB)

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
| 15 | `factory/ui-sync-core/tokens/banxe-tokens.json` | 4.1K | Token source |
| 16 | `factory/p1-summary.md` | 23K | Implementation guide |
| 17 | `factory/rollout-v2-report.md` | 2.3K | Deployment log |

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
| banxe-tokens.json | **primary** | — | — | — |
| rollout-v2-report.md | **primary** | — | — | — |
| p1-summary.md | — | — | **mixed** | — |

**Result:** 16 of 17 files are pure factory-governance. 1 file (`p1-summary.md`) is mixed — contains factory-level recommendations interleaved with bank-project-specific implementation details (hooks for `banxe-payment-core`, subagents for `banxe-ui`, MCPs for `banxe-infra`). <!-- META-MENTION-OK -->

## 3. Conflict Map

**No conflicts detected between any files.**

All 17 files are internally consistent. The Decision-Making Axiom in CANON.md is respected or explicitly restated in every agent spec and operational doc. No file contradicts another.

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
5. **Token single-source** — `banxe-tokens.json` is the only token truth; style-dictionary generates platform outputs.

## 5. Weak Points

1. ~~**No dedicated canon-enforcement agent.**~~ **RESOLVED v1.0** — `factory/.claude/agents/canon-guardian.md` created with 4 modes.

2. **`p1-summary.md` is mixed.** Contains bank-project implementation details (specific hooks for `banxe-payment-core`, subagents for `banxe-ui`) alongside factory-level patterns <!-- META-MENTION-OK -->. **RED-OPEN** per v1.3 §7: factory patterns not yet migrated into `docs/canon/PATTERNS.md`.

3. ~~**No canon versioning.**~~ **RESOLVED v1.0** — CANON.md carries `Canon version: 1.3, Date: 2026-05-23`.

4. ~~**No canon diff policy.**~~ **RESOLVED v1.0** — CANON-TOPOLOGY.md §4 defines change procedure.

5. **`style-dictionary.config.js` not in audit scope of any agent.** **YELLOW** — now listed in CANON-TOPOLOGY.md hierarchy, but factory-watchdog Mode 3 check #8 references it without explicit JS config drift verification logic.

## 6. Recommendations

1. Create `factory/.claude/agents/canon-guardian.md` — dedicated agent for canon document consistency enforcement.
2. Create `factory/docs/canon/CANON-TOPOLOGY.md` — defines which files are canon sources vs copies vs mirrors.
3. Add version/date header to CANON.md.
4. Split `p1-summary.md`: extract reusable factory patterns into `factory/docs/canon/`, leave bank-specific items as historical reference.
5. Define canon diff propagation procedure in CANON-TOPOLOGY.md.
