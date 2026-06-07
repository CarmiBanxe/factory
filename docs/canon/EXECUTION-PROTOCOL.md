# EXECUTION PROTOCOL — Definition of Done & the Controller

**Canon status:** BINDING. Applies to every task given to any factory agent (human or AI), on every terminal (A / Central / B).
**Version:** 1.0
**Date:** 2026-06-07
**Author:** Comet, on instruction of the Owner.
---

## 1. The core problem (plain language)

You give a task. The agent does part of it, then writes a confident report that sounds finished. You cannot tell from the report what was actually done, what was skipped, and what was impossible. Trust breaks.

This protocol fixes it with three things:
1. A strict **Definition of Done**.
2. A mandatory **report format in simple language**, always.
3. A **Controller-Agent** that checks every report before it reaches you.

---

## 2. Definition of Done (DoD)

A task is DONE only if ALL of the following are true:
- Every sub-item of the task has a status: DONE, BLOCKED, or DELEGATED. Nothing is left unmentioned.
- Every DONE item has **evidence** (commit hash, file path, URL, or command output).
- Every BLOCKED item names the **exact blocker** and who/what is needed to unblock.
- Every DELEGATED item names the **owner** and where it was recorded (e.g. OPEN-GAPS.md row).
- A single honest **completion percentage** is stated, computed as DONE items / total items.

If any sub-item has no status, the task is NOT done. The Controller rejects it.

---

## 3. Mandatory report format (always, in simple language)

Every task report MUST end with this block, written so a non-engineer can read it:

```
=== REPORT ===
TASK: <one sentence, what was asked>
DONE (X of Y):
  - <item> — evidence: <hash/path/url>
BLOCKED:
  - <item> — blocker: <reason> — needs: <what/who>
DELEGATED:
  - <item> — owner: <who> — tracked in: <where>
NOT DONE / SKIPPED:
  - <item> — why
COMPLETION: <N>%  (honest, = DONE / TOTAL)
NEXT SINGLE STEP: <one action, per Decision-Making Axiom>
=== END REPORT ===
```

Rules:
- No flattery, no filler. Plain language.
- Never claim 100% unless DONE count == TOTAL count with evidence for each.
- If completion < 100%, the report MUST say so in the first line the Owner reads.
- Honesty over optimism. An honest 40% beats a fake 100%.

---

## 4. The Controller-Agent

### 4.1 Identity
- **Name:** `factory-controller`
- **Type:** base AI-agent living in the factory (per Ideology rule 3: base in factory, domain fork in project).
- **Role-anchor:** quality/governance. It produces NO code and NO specs. It only verifies.
- **Lives in:** `factory/quality-core/.claude/agents/factory-controller.md` (to be created as the agent definition; this canon file authorizes it).

### 4.2 Authority
The Controller is the LAST gate before any task report reaches the Owner. It can:
- ACCEPT a report (format valid, evidence present, percentage honest).
- REJECT a report and send it back with a reason (missing status, missing evidence, inflated percentage, unmentioned sub-items).

The Controller cannot itself mark work as done. It only checks honesty and completeness.

### 4.3 Controller checklist (runs on every report)
1. Does every sub-item of the original task appear with a status? If no → REJECT.
2. Does every DONE item have verifiable evidence? If no → REJECT.
3. Is the COMPLETION % equal to DONE/TOTAL? If inflated → REJECT.
4. Are BLOCKED items recorded in OPEN-GAPS.md with an owner? If no → REJECT.
5. Is the report in the mandatory plain-language format (Section 3)? If no → REJECT.
6. Does any DONE claim contradict OPEN-GAPS.md (gap still OPEN)? If yes → REJECT.

Only if all six pass does the report reach the Owner with a Controller stamp:
`[CONTROLLER: ACCEPTED — X/Y done, N% honest]`.

### 4.4 Escalation
- If the same task is rejected 3 times, the Controller escalates to the Owner with a plain-language summary of why it keeps failing.
- The Controller never silently passes a partial task as complete.

---

## 5. Binding into canon

- This file is canon. The Decision-Making Axiom (one sequential next step) and the Epistemic Accuracy Guard (FACT / ВЫВОД / НЕИЗВЕСТНО tagging) already exist in CANON.md; this protocol operationalizes them for task delivery.
- The `factory-controller` agent is hereby designated the enforcer of this protocol.
- OPEN-GAPS.md is the shared ledger the Controller checks against.
- Proposed CANON.md addition (when the 1.6.1 -> 1.7 bump is approved, gap G7):
  "7. Definition of Done & Controller: no task is reported complete without a plain-language DONE/BLOCKED/DELEGATED report verified by factory-controller (see EXECUTION-PROTOCOL.md)."

---

## 6. Open items created by this protocol (tracked in OPEN-GAPS.md)
- Create the agent definition file `factory/quality-core/.claude/agents/factory-controller.md` (implementation of this spec).
- Add canon rule 7 to CANON.md at the 1.7 bump (gap G7).
