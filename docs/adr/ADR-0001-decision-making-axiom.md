# ADR-0001 — Decision-Making Axiom as Factory Canon

- Status: Accepted
- Date: 2026-05-23
- Canon version: 1.2
- Source of truth: factory/CANON.md

## Context

Factory governance previously allowed agents to surface multiple options (A/B/C) and to ask clarifying questions on safe commands. This created two structural problems:

1. Cognitive overhead on the user for routine decisions that an agent can resolve optimally.
2. Inconsistent behavior across agents (canon-guardian, factory-watchdog, ui-sync) and Claude Code sessions, because "best practice" was implicit rather than canonical.

A single, machine-enforceable decision rule was required.

## Decision

The Decision-Making Axiom is adopted as the foundational rule of the factory:

1. Always select the globally optimal solution among all admissible options.
2. Never present parallel alternatives. Only one sequential next step is allowed per turn.
3. After any analysis or output, automatically choose the best solution without asking the user.
4. Every continuation must produce exactly one of:
   - a single shell command, or
   - a single Claude Code prompt.
5. This axiom applies to all factory operations and overrides any prior multi-option pattern.

This axiom is canonical, versioned, and propagated to all controlled copies via canon-guardian.

## Consequences

- Agents must not surface A/B/C choices to the user; multi-option reasoning is internal (Decision-Brief).
- Agents must not ask clarifying questions on safe commands.
- Every reply must end with exactly one next step (shell command or Claude Code prompt) with an explicit insertion target.
- canon-guardian enforces axiom consistency across CANON.md, .clauderules, factory-watchdog, ui-sync, banxe-repo-template, and addenda.
- Any future relaxation requires a new ADR superseding this one and a major version bump of CANON.md (X.0).

## Scope

- Applies to factory governance (L0–L2) and all enforcement artifacts (L3).
- Applies to all Claude Code sessions operating inside this repository.
- Does not apply to bank-project business logic, which is owned by downstream repos.

## Non-legal scope

Legal-domain reasoning patterns (CURIA/HUDOC/EUR-Lex/HAL/SSRN/Cairn search overrides, ratio decidendi, dispositif, Plan 7, !legalqa, !ultralegal, !ultralegalstrategy) are explicitly excluded from this axiom and from the canon at large.

## References

- factory/CANON.md (Canon version: 1.2, 2026-05-23)
- factory/docs/canon/CANON-TOPOLOGY.md
- factory/docs/canon/CANON-AUDIT-REPORT.md
- factory/.claude/agents/canon-guardian.md
