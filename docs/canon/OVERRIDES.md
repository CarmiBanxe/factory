Canon version: 1.3
Date: 2026-05-23

# Factory Override Commands — Operational Definitions

This document is the canonical operational definition source for override commands listed in CANON.md v1.3 §10.
Without these definitions, names are not part of the canon (CANON.md v1.3 §6).

## Common contract for every override

- An override is a режимный тумблер, not an action.
- An override may only strengthen the Decision-Making Axiom, never weaken it.
- Every override must report its activation explicitly at the start of the agent output.
- Multiple overrides may be combined; conflicts resolve by selecting the strictest interpretation.
- Forbidden overrides (legal/court/academic-legal) are listed in CANON.md v1.3 §10 and must be refused.

## Format for each override

For each command:
- Purpose
- Effect on pipeline
- Required output additions
- Prohibitions while active
- Enforcement level

---

## !reset
- Purpose: drop all transient session state for the current agent.
- Effect: clears in-memory todo lists, partial drafts, cached findings.
- Required output: state "reset acknowledged" + one next atomic step.
- Prohibitions: do not delete any committed canon artifact, do not touch git history.
- Enforcement level: L0.

## !savestate
- Purpose: persist current agent reasoning state into a snapshot.
- Effect: writes a structured snapshot (todo list, hypotheses, open RED items) to working memory or a file under docs/snapshots/ if allowed.
- Required output: snapshot identifier and a short manifest of saved fields.
- Prohibitions: must not save anything outside the canon-allowed paths.
- Enforcement level: L0.

## !loadstate
- Purpose: restore a previously saved snapshot.
- Effect: agent re-enters the saved reasoning state and continues from there.
- Required output: snapshot identifier and a diff vs current state if any.
- Prohibitions: must not silently overwrite current uncommitted work.
- Enforcement level: L0.

## !deepanalysis
- Purpose: run a deeper-than-default analytical pass.
- Effect: agent expands the depth of reasoning (more decomposition, more sub-checks).
- Required output: enumerated reasoning steps + explicit assumptions list.
- Prohibitions: must not produce multiple parallel alternatives; final output remains one next step.
- Enforcement level: L0.

## !ultradeep
- Purpose: maximum depth analytical pass.
- Effect: forces full multi-view + adversarial QC + falsification cascade per CANON.md v1.2 §5.
- Required output: all three QC sections + final reconciled conclusion.
- Prohibitions: no shortcuts on QC steps.
- Enforcement level: L0.

## !factcheck
- Purpose: explicit verification of factual claims in the agent's output.
- Effect: every [FACT] marker must be backed by an explicit source or "cannot verify".
- Required output: factcheck table or inline citations per item.
- Prohibitions: must not soft-classify [НЕИЗВЕСТНО] as [FACT].
- Enforcement level: L0.

## !biascheck
- Purpose: examine the agent's own reasoning for systematic bias.
- Effect: adds an explicit "bias review" section.
- Required output: enumerated biases considered + how the output mitigates each.
- Prohibitions: bias review may not soften factual findings.
- Enforcement level: L0.

## !logiccheck
- Purpose: explicit validation of the logical structure of the agent's reasoning.
- Effect: agent runs through each step looking for non-sequiturs and missing premises.
- Required output: validated step list + any fixed gaps.
- Prohibitions: must not invent missing premises silently.
- Enforcement level: L0.

## !consistency
- Purpose: check internal consistency of the agent's claims with earlier turns or canon files.
- Effect: cross-references current output against canon and conversation history.
- Required output: consistency table (claim vs anchor).
- Prohibitions: must not silently retract earlier statements.
- Enforcement level: L0.

## !gapsanalysis
- Purpose: enumerate gaps in evidence, scope, or reasoning.
- Effect: produces an explicit list of what is missing.
- Required output: gap list with severity.
- Prohibitions: must not omit known gaps to make the output look complete.
- Enforcement level: L0.

## !assumptions
- Purpose: surface all implicit assumptions.
- Effect: agent restates each assumption that the output depends on.
- Required output: numbered assumptions list.
- Prohibitions: must not bury assumptions in prose.
- Enforcement level: L0.

## !implications
- Purpose: surface downstream implications of the proposed step.
- Effect: agent enumerates 2nd-order effects on canon, repos, agents.
- Required output: implication list grouped by domain.
- Prohibitions: must not understate negative implications.
- Enforcement level: L0.

## !alternatives
- Purpose: internal exploration of alternative paths.
- Effect: agent considers other admissible solutions and explains why the chosen one is optimal.
- Required output: ABC trade-off table internal to the output; final output remains one next step (CANON.md v1.2 §4 Decision-Brief).
- Prohibitions: must not present alternatives as a user-facing choice.
- Enforcement level: L0.

## !edgecases
- Purpose: enumerate edge cases the proposed step must handle.
- Effect: agent stress-tests the proposal against boundary conditions.
- Required output: edge case list with handling per case.
- Prohibitions: must not skip irreversible-action edge cases.
- Enforcement level: L0.

## !worstcase
- Purpose: project the worst plausible outcome of the proposed step.
- Effect: agent describes the failure mode and impact.
- Required output: worst-case description + reversibility assessment.
- Prohibitions: must not minimise worst-case severity.
- Enforcement level: L0.

## !bestcase
- Purpose: project the best plausible outcome of the proposed step.
- Effect: agent describes the success mode.
- Required output: best-case description.
- Prohibitions: best-case framing must not displace worst-case in priority.
- Enforcement level: L0.

## !riskassessment
- Purpose: structured risk evaluation per CANON.md v1.2 §8 Plan-Risk-Block.
- Effect: agent produces a risk matrix (likelihood x impact) for the proposed step.
- Required output: risk matrix + mitigations.
- Prohibitions: must not proceed with destructive action while risks are uncontrolled.
- Enforcement level: L1.

## !opportunityscan
- Purpose: surface adjacent improvements the step enables.
- Effect: agent lists secondary opportunities unlocked by the proposed step.
- Required output: opportunity list with effort estimate.
- Prohibitions: must not derail the current atomic step into multi-step refactor.
- Enforcement level: L0.

## !strategicview
- Purpose: zoom out to factory-level strategic impact.
- Effect: agent re-anchors the proposed step against CANON.md v1.3 §13 Layer priority and overall factory roadmap.
- Required output: strategic alignment note.
- Prohibitions: must not propose strategic pivots without explicit user mandate.
- Enforcement level: L0.

## !tacticalplan
- Purpose: produce a tight tactical sequence for executing the next phase.
- Effect: agent breaks the next phase into atomic steps with order.
- Required output: ordered atomic step list.
- Prohibitions: tactical plan does not replace the single next step in output; the user must still receive exactly one next step.
- Enforcement level: L0.

## !implementation
- Purpose: focus output on concrete implementation of the next step.
- Effect: agent produces the exact shell command or Claude Code prompt to execute.
- Required output: one shell command or one Claude Code prompt with explicit insertion target.
- Prohibitions: no theoretical detours.
- Enforcement level: L0.

## !monitoring
- Purpose: define monitoring/verification of the executed step.
- Effect: agent describes how success of the step will be observed.
- Required output: monitoring checklist.
- Prohibitions: must not omit verification.
- Enforcement level: L0.

## !iterate
- Purpose: run an explicit iteration cycle on the current artifact.
- Effect: agent applies one improvement pass and reports the diff.
- Required output: pre/post diff summary.
- Prohibitions: must not silently rewrite controlled copies.
- Enforcement level: L1.

## !validate
- Purpose: validate an artifact against canon.
- Effect: agent runs the relevant canon checks (axiom alignment, enforcement level, scope rules).
- Required output: PASS/FAIL per check + traffic-light overall.
- Prohibitions: PASS without self-critique is forbidden (CANON.md v1.2 §12).
- Enforcement level: L1.

## !document
- Purpose: produce or update canonical documentation for the current artifact.
- Effect: agent writes/updates the matching .md under docs/canon/ or docs/adr/.
- Required output: file path + diff or new content.
- Prohibitions: documentation must not contradict the source of truth (CANON.md).
- Enforcement level: L1.

## !visualize
- Purpose: produce an ASCII/text diagram of the artifact or flow.
- Effect: agent emits a code-block diagram (no images).
- Required output: text diagram.
- Prohibitions: no binary attachments, no external image hosting.
- Enforcement level: L0.

## !simplify
- Purpose: reduce surface of the current artifact without changing canonical behavior.
- Effect: agent proposes minimal cuts and explains canon-preservation.
- Required output: diff + canon-preservation note.
- Prohibitions: must not weaken any axiom rule or extension.
- Enforcement level: L1.

## !strict
- Purpose: maximum-strictness mode.
- Effect: applies CANON.md v1.2 §3 Instruction strictness literally; refuses any reinterpretation of the user's literal instruction.
- Required output: explicit statement "strict mode active" + one next step that matches the user's wording verbatim.
- Prohibitions: no inference of "what the user probably meant"; on ambiguity decide by the best-solution principle and act on safe commands, otherwise stop and report.
- Enforcement level: L1.

## !falsify
- Purpose: force a falsification attempt on the agent's own proposed conclusion (Popperian QC per CANON.md v1.2 §5).
- Effect: agent constructs the strongest counter-argument to its own PASS verdict; if the counter holds, PASS becomes FAIL.
- Required output: counter-argument section + reconciled verdict.
- Prohibitions: superficial counters are forbidden; must engage the strongest available objection.
- Enforcement level: L1.

## !brief
- Purpose: compress output to minimum tokens without dropping canonical fields.
- Effect: agent removes prose, keeps [FACT] / [ВЫВОД] / [НЕИЗВЕСТНО] markers and the single next step.
- Required output: terse bullets only; no preambles.
- Prohibitions: must not drop traffic-light classification or enforcement level when those are required.
- Enforcement level: L0.

## !selfcrit
- Purpose: explicit self-critique pass before emitting any PASS verdict (mandatory per CANON.md v1.2 §12).
- Effect: agent argues against its own draft conclusion before finalising it.
- Required output: self-critique section followed by either confirmed PASS or revised verdict.
- Prohibitions: PASS without preceding self-critique is invalid.
- Enforcement level: L1.

---

## Combination rules

- When multiple overrides are active, the strictest interpretation wins.
- `!ultradeep` implies `!deepanalysis`, `!selfcrit`, `!falsify`, `!biascheck`, `!logiccheck`.
- `!strict` overrides any softening interpretation in any other modifier.
- `!brief` cannot suppress required output fields demanded by another active override.

## Forbidden modifiers (verbatim from CANON.md v1.3 §10)

The following modifiers are forbidden and must be refused without execution:

- !eucourt
- !echrsearch
- !cjeusearch
- !academic-legal
- !ultralegal
- !legalqa
- !ultralegalstrategy

Any other legal-domain or court-search override falls under the same prohibition.

## Anchoring

This document realises CANON.md v1.3 §6 (Module/Override Operational Definitions requirement) for the override list in CANON.md v1.3 §10. Without this document, the override names in §10 are not part of the canon.
