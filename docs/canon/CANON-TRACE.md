# CANON-TRACE — Source-to-Canon Integration Trace v2

Canon version: 1.4.1
Date: 2026-05-25
Method: line-by-line verification (Sprint 2, B1)

---

## 1. CORE v4.11.1 mapping

Anchored to: `/home/mmber/factory/.canon-sources/CORE-v4.11.1.md` (local reference, gitignored).

| CORE section | CORE line | Canon target | Status |
|---|---|---|---|
| §0 Назначение | 5 | CANON.md §1 (axiom) | INTEGRATED |
| §1.1 Авто-Канон+ | 20 | CANON.md §1 (axiom) | INTEGRATED |
| §1.2 CANON_PREFLIGHT | 24 | OVERRIDES.md !safe + CANON.md §Pre-output lock | INTEGRATED v1.4.0 (Sprint 1 A1) |
| §1.3 Конфликт-чек | 33 | CANON.md §Layer Priority | INTEGRATED |
| §2 EPISTEMIC_ACCURACY_GUARD | 41 | OVERRIDES.md !safe + CANON.md §Epistemic Accuracy Guard | INTEGRATED v1.4.1 (Sprint 2 B2) |
| §3.1-3.2 MODE_SELECTION | 52-56 | CANON.md §Output Style Canon | INTEGRATED |
| §4.1 RESEARCH_BRIEF | 64 | OVERRIDES.md !document + !visualize | ABSORBED (redundant as standalone) |
| §4.2 DECISION_BRIEF | 68 | OVERRIDES.md !brief + CANON.md §Decision-Brief | INTEGRATED v1.4.0 (Sprint 1 A6) |
| §5.1 MULTI_VIEW_REVIEW | 78 | OVERRIDES.md !3views | INTEGRATED v1.4.1 (Sprint 2 B2) |
| §5.2 ADVERSARIAL_QC | 80 | CANON.md §QC cascade | INTEGRATED |
| §5.3 HYBRID_SYNTHESIS | 82 | OVERRIDES.md !dual_mode | INTEGRATED v1.4.1 (Sprint 2 B2) |
| §5.4 FALSIFICATION_REVIEW | 84 | OVERRIDES.md !falsify | INTEGRATED |
| §6 QUESTION_AUDIT | 87 | CANON.md §Question-Audit | INTEGRATED |
| §7 Планирование | 91 | CANON.md §Plan-Risk-Block | INTEGRATED v1.4.0 (Sprint 1 A7) |
| §8 Память | 94 | CANON.md §Snapshot/Update/Rewrite | INTEGRATED |
| §9 OUTPUT_STYLE_CANON | 101 | CANON.md §Output Style Canon | INTEGRATED |
| §10 Управление строгостью | 111 | OVERRIDES.md !strict + !brief | INTEGRATED |
| §11 PATCH-ADDON SAFE | 132 | OVERRIDES.md !safe | INTEGRATED v1.4.1 |
| §11 PATCH-ADDON !3views | 146 | OVERRIDES.md !3views | INTEGRATED v1.4.1 |
| §11 PATCH-ADDON !self_crit | 162 | OVERRIDES.md !selfcrit | INTEGRATED |
| §11 PATCH-ADDON !dual_mode | 175 | OVERRIDES.md !dual_mode | INTEGRATED v1.4.1 |
| ДОПОЛНЕНИЕ 1 !legal_qa | 191 | — | EXCLUDED (legal-domain per CANON.md §exclusions) |
| ДОПОЛНЕНИЕ 2 ultra-legal | 211 | — | EXCLUDED (legal-domain) |

## 2. Universalnyi v4.15.1 mapping

Anchored to: `/home/mmber/factory/.canon-sources/Universalnyi-v4.15.1.md` (local reference, gitignored).

### Commands (lines 294-332)

| Universalnyi command | Line | Canon target | Status |
|---|---|---|---|
| /help | 296 | meta-UX (not canon override) | OUT-OF-SCOPE |
| /reset | 297 | OVERRIDES.md !reset | INTEGRATED |
| /save_state | 298 | OVERRIDES.md !savestate | INTEGRATED |
| /load_state | 299 | OVERRIDES.md !loadstate | INTEGRATED |
| /deep_analysis | 300 | OVERRIDES.md !deepanalysis | INTEGRATED |
| /ultra_deep | 301 | OVERRIDES.md !ultradeep | INTEGRATED |
| /fact_check | 302 | OVERRIDES.md !factcheck | INTEGRATED |
| /bias_check | 303 | OVERRIDES.md !biascheck | INTEGRATED |
| /logic_check | 304 | OVERRIDES.md !logiccheck | INTEGRATED |
| /consistency | 305 | OVERRIDES.md !consistency | INTEGRATED |
| /gaps_analysis | 306 | OVERRIDES.md !gapsanalysis | INTEGRATED |
| /assumptions | 307 | OVERRIDES.md !assumptions | INTEGRATED |
| /implications | 308 | OVERRIDES.md !implications | INTEGRATED |
| /alternatives | 309 | OVERRIDES.md !alternatives | INTEGRATED |
| /edge_cases | 310 | OVERRIDES.md !edgecases | INTEGRATED |
| /worst_case | 311 | OVERRIDES.md !worstcase | INTEGRATED |
| /best_case | 312 | OVERRIDES.md !bestcase | INTEGRATED |
| /risk_assessment | 313 | OVERRIDES.md !riskassessment | INTEGRATED |
| /opportunity_scan | 314 | OVERRIDES.md !opportunityscan | INTEGRATED |
| /strategic_view | 315 | OVERRIDES.md !strategicview | INTEGRATED |
| /tactical_plan | 316 | OVERRIDES.md !tacticalplan | INTEGRATED |
| /implementation | 317 | OVERRIDES.md !implementation | INTEGRATED |
| /monitoring | 318 | OVERRIDES.md !monitoring | INTEGRATED |
| /iterate | 319 | OVERRIDES.md !iterate | INTEGRATED |
| /validate | 320 | OVERRIDES.md !validate | INTEGRATED |
| /document | 321 | OVERRIDES.md !document | INTEGRATED |
| /visualize | 322 | OVERRIDES.md !visualize | INTEGRATED |
| /simplify | 323 | OVERRIDES.md !simplify | INTEGRATED |
| /feedback_loop | 319 | OVERRIDES.md !feedbackloop | INTEGRATED v1.4.1 (Sprint 2 B2) |
| /auto_verify | 330 | OVERRIDES.md !autoverify | INTEGRATED v1.4.1 (Sprint 2 B2) |
| /check_compatibility | 331 | OVERRIDES.md !checkcompat | INTEGRATED v1.4.1 (Sprint 2 B2) |
| !право.* | 325-328 | — | EXCLUDED (legal-domain) |

### Modules (lines 657-668)

| Universalnyi module | Line | Canon target | Status |
|---|---|---|---|
| technical_module | 657 | MODULES.md technical | INTEGRATED |
| medical_module | 658 | — | EXCLUDED (out-of-scope; CANON.md §11 Forbidden modules, Sprint 2 B3) |
| legal_module | 659 | — | EXCLUDED (legal-domain) |
| legal_fr | 660 | — | EXCLUDED (legal-domain) |
| legal_eu | 661 | — | EXCLUDED (legal-domain) |
| financial_module | 662 | MODULES.md financial | INTEGRATED |
| scientific_module | 663 | MODULES.md scientific | INTEGRATED |
| creative_module | 664 | MODULES.md creative | INTEGRATED |
| educational_module | 665 | MODULES.md educational | INTEGRATED |
| business_module | 666 | MODULES.md business | INTEGRATED |
| academic_module | 668 | — | EXCLUDED (academic-legal domain) |

### Cognitive method modules (lines 529-569, "СПЕЦИАЛИЗИРОВАННЫЕ МОДУЛИ")

| Cognitive module | Lines | Canon target | Status |
|---|---|---|---|
| Модуль критического мышления | 529-537 | OVERRIDES.md !logiccheck + !biascheck + !falsify | ABSORBED |
| Модуль решения проблем | 538-546 | OVERRIDES.md !alternatives + !tacticalplan + !implementation | ABSORBED |
| Модуль креативности | 547-555 | MODULES.md creative + OVERRIDES.md !alternatives | ABSORBED |
| Модуль системного анализа | 556-563 | OVERRIDES.md !gapsanalysis + !consistency | ABSORBED |
| Модуль коммуникации | 564-569 | CANON.md §Output Style Canon (partial) | PARTIALLY ABSORBED |

## 3. Anchoring

- Sources are local reference copies in `.canon-sources/` (gitignored).
- Sprint 2 (B1) completed line-by-line verification 2026-05-25.
- Total: CORE v4.11.1 — 22 sections mapped (19 integrated, 2 excluded legal, 1 absorbed).
- Total: Universalnyi v4.15.1 — 35 commands mapped (31 integrated, 3 excluded legal/UX, 1 out-of-scope), 11 modules mapped (6 integrated, 5 excluded), 5 cognitive modules absorbed.
- Discrepancy with transition packet §3 ("15 required status checks"): actually 1 required context "Axiom consistency + factory/project separation" containing 19 internal L2 steps. To be fixed in canon §3 mirror, Sprint 4.

**Rejection policy applied:** All features belonging to the legal domain (court searches, legal reasoning engines, jurisdiction-specific citation, legal module loaders, academic legal databases) are rejected per CANON.md v1.2 §10 (forbidden modifiers) and §11 (forbidden modules). Medical module excluded per CANON.md §11 (harm-safety conflict, licensed practitioners requirement). This is a factory-level policy decision, not a per-case evaluation.

**Filtered vs integrated:** Features marked "INTEGRATED" were adopted verbatim or with minimal renaming (snake_case → camelCase). Features marked "ABSORBED" were consolidated into existing canon sections rather than given standalone overrides. Features marked "PARTIALLY ABSORBED" had some elements integrated while others were deemed redundant.
