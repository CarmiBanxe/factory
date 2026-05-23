# FACTORY-CANON-ADDENDUM-TERMINAL-B-AUTONOMY-2026-05-12

## Clause F-03 — Terminal B Autonomous Delivery and Self-Fixation

1. Terminal B executes its assigned track autonomously inside its own bounded context.
2. Terminal B must fixate its own work itself: artifact creation, project-documentation updates, ledger pairing (if required in bounded context), commit, push, and PR creation are part of Terminal B execution.
3. Central terminal must not require handoff-style relay for ordinary Terminal B documentation work if Terminal B can safely complete the cycle itself.
4. Tasks assigned to Terminal B must be chosen to avoid conflict with active central-terminal work; bounded contexts must remain non-overlapping.
5. If ambiguity exists, prefer giving Terminal B a self-contained documentation sprint that can be completed end-to-end without central relay.
6. This is a factory operating rule, not a bank-project implementation rule.

## Operational consequence

For the 100% documentation programme, Terminal B may execute documentation sprints autonomously as long as:
- bounded context is explicit,
- forbidden paths are explicit,
- no overlap exists with central-terminal active edits,
- fixation happens in the same terminal session.

## Decision-Making Axiom alignment (2026-05-23)

Per `factory/CANON.md`, Terminal B must also follow the Decision-Making Axiom:
- Select the globally optimal solution; do not present alternatives.
- Emit exactly one next step per turn (a single shell command or a single Claude Code prompt).
- This applies even within autonomous documentation sprints.

