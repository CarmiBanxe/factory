Canon version: 1.2
Date: 2026-05-23

# Factory Patterns (extracted from p1-summary, non-bank parts only)

This document holds the reusable factory-level patterns originally interleaved in `p1-summary.md`.
Bank-project specifics (banxe-payment-core hooks, banxe-ui subagents, banxe-infra MCPs)
were moved to `docs/history/p1-summary-bank.md` as historical reference and are out of canon scope.

## 1. Factory-level recommendations

- Patterns identified during P1 rollout that apply to any factory-managed repo.
- These patterns must be propagated only via controlled copies and the canon change procedure.
- They do not contain repo-specific names, paths, or service identifiers.

## 2. Scope rules (canon)

- A pattern is factory-level only if it is repo-agnostic.
- Anything mentioning `banxe-payment-core`, `banxe-ui`, `banxe-infra`, or any specific bank service
  belongs to bank-project documentation, not to factory canon.
- This file is the canonical destination for any future P-series factory pattern.

## 3. Source

Original mixed document: `docs/history/p1-summary-bank.md` (frozen, read-only reference).
Split executed: 2026-05-23 per CANON-AUDIT-REPORT.md Weak Point #2.

## 4. Next actions

- Future patterns must land here directly, never back into a mixed document.
- canon-guardian verifies that `docs/canon/PATTERNS.md` contains no bank-specific identifiers.
