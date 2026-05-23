# CANON-TRACE — Source-to-Canon Integration Trace

Canon version: 1.3
Date: 2026-05-23

---

## 1. CORE v4.11.1 mapping

| External feature | Canon section / file | Status |
|---|---|---|
| EXECUTION-LOCK / CANON-PREFLIGHT | CANON.md v1.2 §1 Pre-output lock | INTEGRATED |
| EPISTEMIC ACCURACY GUARD | CANON.md v1.2 §2 + v1.3 §1 Honest Reporting | INTEGRATED |
| INSTRUCTION STRICTNESS | CANON.md v1.2 §3 | INTEGRATED |
| RESEARCH-BRIEF | not required (internal-only DECISION-BRIEF kept) | REJECTED (redundant) |
| DECISION-BRIEF | CANON.md v1.2 §4 (internal only) | INTEGRATED |
| QC cascade (multi-view + adversarial + falsification) | CANON.md v1.2 §5 | INTEGRATED |
| QUESTION-AUDIT | CANON.md v1.2 §6 | INTEGRATED |
| OUTPUT-STYLE-CANON | CANON.md v1.2 §7 | INTEGRATED |
| PLAN-RISK-BLOCK | CANON.md v1.2 §8 | INTEGRATED |
| OVERRIDE commands (!3views, !selfcrit, !dualmode) | docs/canon/OVERRIDES.md | INTEGRATED (filtered) |
| Self-Critique by default | CANON.md v1.2 §12 | INTEGRATED |
| askoff / askstrict / askdefault modes | CANON.md v1.2 Appendix A (askoff default) | INTEGRATED |
| Value-first output discipline | CANON.md v1.2 Appendix C (value-first violation = blocker) | INTEGRATED |
| BriefOnce rule | CANON.md v1.2 Appendix A | INTEGRATED |
| Ultra-Legal-Reasoning | — | REJECTED (legal-domain) |
| !legalqa, !ultralegal, !ultralegalstrategy | — | REJECTED (legal-domain) |
| ratio decidendi | — | REJECTED (legal-domain) |
| CURIA / HUDOC search integration | — | REJECTED (legal-domain) |
| Court hierarchy mapping (CJEU, ECHR, national) | — | REJECTED (legal-domain) |
| Legal citation format enforcement | — | REJECTED (legal-domain) |

## 2. Universalnyi v4.15.1 mapping

| External feature | Canon section / file | Status |
|---|---|---|
| SNAPSHOT / UPDATE / REWRITE | CANON.md v1.2 §9 | INTEGRATED |
| No-Silent-Rewrite | CANON.md v1.2 §9 | INTEGRATED |
| Layer priority L0>L1>L2>L3 | CANON.md v1.2 §13 | INTEGRATED |
| Override command vocabulary (!reset, !savestate, !loadstate, !deepanalysis, !ultradeep, !factcheck, !biascheck, !logiccheck, !consistency, !gapsanalysis, !assumptions, !implications, !alternatives, !edgecases, !worstcase, !bestcase, !riskassessment, !opportunityscan, !strategicview, !tacticalplan, !implementation, !monitoring, !iterate, !validate, !document, !visualize, !simplify, !strict, !falsify, !brief, !selfcrit) | docs/canon/OVERRIDES.md (31 commands) | INTEGRATED |
| Module loader (technical, financial, scientific, creative, educational, business) | docs/canon/MODULES.md | INTEGRATED |
| Module loader (legal, legalfr, legaleu, legalqa, ultralegal, academic-legal) | — | REJECTED (legal-domain) |
| ABRUPT-STOP on context budget (70/85/95%) | CANON.md v1.2 §8 | INTEGRATED |
| Triggers (GO, execute now, TLDR, split on/off, publish part N, publish all, askdefault, askstrict, askoff, noplan, confidence on/off, reset, clearmemory, forget N, panic, sethooks L2, addattachment, version save/diff, report show/brief, index/toc/anchors/glossary build, split continue/stop, publish resume, runqa, qafix, finalize ready?/confirm) | CANON.md v1.2 Appendix B | INTEGRATED (filtered) |
| Blockers (silent rewrite, async multi-stream, split violation, missing REPORT, missing saveline, missing checksum, platform compat violation, value-first violation, QA fail without self-critique) | CANON.md v1.2 Appendix C | INTEGRATED (filtered) |
| Final checklist CL01..CL10 | CANON.md v1.2 Appendix D | INTEGRATED (filtered) |
| Policy compact (hierarchy enforcement, no async, split rules, integration mode, report counters, BriefOnce, Decision-Brief internal) | CANON.md v1.2 Appendix A | INTEGRATED (filtered) |
| CURIA / HUDOC / EUR-Lex searches | — | REJECTED (legal-domain) |
| HAL / SSRN / Cairn academic searches | — | REJECTED (legal-domain) |
| !eucourt, !echrsearch, !cjeusearch | — | REJECTED (legal-domain) |
| !academic hal/ssrn/cairn | — | REJECTED (legal-domain) |
| autoverify modes (strict, lax) | docs/canon/OVERRIDES.md !strict + CANON.md v1.2 §2 Epistemic Accuracy Guard | INTEGRATED (filtered) |
| Confidence scoring (confidence on/off) | CANON.md v1.2 Appendix B (trigger) | INTEGRATED |
| Platform compatibility guard | CANON.md v1.2 Appendix C + Appendix D CL09 | INTEGRATED |
| Checksum/hash on canon change | CANON.md v1.2 Appendix D CL10 | INTEGRATED |

## 3. Anchoring

This trace realises CANON.md v1.3 §5 (Source-to-Canon Trace requirement).
Without this file, integration of CORE v4.11.1 and Universalnyi v4.15.1 into the factory canon is not valid per v1.3 rules.

**Rejection policy applied:** All features belonging to the legal domain (court searches, legal reasoning engines, jurisdiction-specific citation, legal module loaders, academic legal databases) are rejected per CANON.md v1.2 §10 (forbidden modifiers) and §11 (forbidden modules). This is a factory-level policy decision, not a per-case evaluation — legal capabilities are excluded from the factory canon entirely.

**Filtered vs integrated:** Features marked "INTEGRATED (filtered)" were adopted with modifications — typically removal of legal-domain examples, removal of multi-option output patterns (axiom compliance), or consolidation with existing canon sections to avoid duplication.
