Canon version: 1.6.1
Date: 2026-05-23

# Factory Patterns (extracted from p1-summary, factory-level only)

This document is the canonical destination for repo-agnostic factory patterns.
Bank-project specifics (banxe-payment-core, banxe-ui, banxe-infra) <!-- META-MENTION-OK -->
are kept as historical reference in docs/history/p1-summary-bank.md and are out of canon scope.

## Scope rules

- A pattern lives here only if it is repo-agnostic.
- If a pattern mentions a specific bank service name, a specific invariant ID, or a specific repo path, it belongs to bank-project documentation, not to factory canon.
- This file is propagated only via the canon change procedure defined in CANON-TOPOLOGY.md §4.

## 1. Hook patterns (Claude Code automations)

### 1.1 PostToolUse — format + check on changed files
- After every edit of a source file, run language-appropriate formatter and linter on the changed file only.
- Must be silent on no-op, hard-fail on lint violations.
- Applies to any language with a deterministic formatter.
- Enforcement level: L1 minimum, L2 if integrated into required status checks.

### 1.2 PreToolUse — sensitive-path guard + targeted SAST
- Before any edit, check that the path is not in a denylist of sensitive areas (secrets, compliance raw data, KYC raw, billing live config).
- On any touched file, run a focused SAST pass with the strictest factory ruleset for that file type.
- Must hard-fail before the edit, not after.
- Enforcement level: L2 minimum.

## 2. Subagent patterns

### 2.1 Invariant reviewer
- Subagent whose only job is to verify domain invariants on every PR.
- Inputs: PR diff + invariant catalogue.
- Output: structured pass/fail per invariant + one atomic next step on first FAIL.
- Must follow Decision-Making Axiom: one next step, no parallel alternatives.

### 2.2 Security reviewer
- Subagent that runs domain-specific security checks (PCI/PAN, secrets exposure, regulated data handling).
- Operates read-only on the diff, never proposes direct edits to compliance-sensitive paths.
- Reports findings using traffic-light per CANON.md v1.3 §1.

### 2.3 Money-safety reviewer
- Subagent that enforces money-safety invariants on any code path touching monetary values.
- Forbids float for money, enforces Decimal/equivalent, checks for tabular-num display.

### 2.4 AI-content reviewer
- Subagent that reviews AI-generated content for hallucination markers, missing disclosures, unverifiable claims.
- Applies CANON.md v1.2 §2 Epistemic Accuracy Guard.

## 3. CI workflow patterns

### 3.1 Hard-fail on security gates
- continue-on-error: true on semgrep, SAST, secret-scan, license-scan is a critical anti-pattern and forbidden by factory policy.
- Every security gate must be blocking.
- Enforcement level: L2 for any security gate in a regulated-domain repo.

### 3.2 Coverage gate enforced, not just reported
- Coverage thresholds must be enforced (--cov-fail-under=N), not merely uploaded.
- Factory minimum is defined in factory/quality-core/workflows/quality-gate.yml; per-repo overrides may raise but not lower it.

### 3.3 Concurrency control for money-touching workflows
- Any workflow that touches live money paths (deploy, migration, settlement, payout) must have concurrency with cancel-in-progress: false.
- Enforcement level: L2.

### 3.4 Auto PR review without explicit invocation
- PR-review automation must trigger on every PR without requiring an explicit mention.
- Manual invocation is additive, not the only path.

### 3.5 Frontend PostToolUse: typecheck + lint on changed file
- For frontend repos, on each edit run project typecheck plus lint on the changed file.

### 3.6 Priority ladder for workflow gaps
- P0 = security or money-correctness gap; fix immediately.
- P1 = automation preventing drift or repeated human work.
- P2 = DX or observability improvement.
- Lower-priority items are not addressed before higher-priority items are closed.

## 4. MCP server selection patterns

### 4.1 Already-configured MCPs require explicit accept-or-remove decision
- No "keep by default" without justification.

### 4.2 Domain-must-have MCPs
- For a regulated-fintech repo, MCPs covering security scanning, compliance evidence, and observability are factory-recommended baseline.

### 4.3 MCPs to explicitly avoid
- Any MCP that introduces a new source of truth outside the factory canon is forbidden by default.
- Complements CANON.md v1.2 §9 (Snapshot/Update/Rewrite + No-Silent-Rewrite).

## 5. Skill patterns (custom)

### 5.1 Custom skills are advisory unless explicitly promoted
- A custom skill cannot edit canonical artifacts.
- Promotion requires the canon change procedure (CANON-TOPOLOGY.md §4).
- Example: factory/ui-sync-core/.claude/skills/lazyweb-research.md.

## 6. PR review patterns

### 6.1 Automatic PR review on every PR
- Factory baseline is automatic review on each PR, not on-demand.

### 6.2 Quality gates separated from review automation
- Quality gates (CI checks) and review automation (LLM PR review) are distinct concerns and must live in separate workflows.
- Failure of review automation must not silently skip quality gates.

## 7. Mapping to canon

Every pattern depends on one or more sections of factory/CANON.md v1.6.1:
- §1 Decision-Making Axiom: hard-fail gates, single-next-step subagents.
- v1.2 §1 Pre-output lock: pre-edit guards, sensitive-path checks.
- v1.2 §2 Epistemic Accuracy Guard: AI-content reviewer.
- v1.2 §5 QC cascade: invariant + security + money-safety reviewers.
- v1.2 §8 Plan-Risk-Block: concurrency control on money paths.
- v1.3 §1 Honest Reporting: traffic-light in subagent outputs.
- v1.3 §3 Enforcement Levels: each pattern carries an L0/L1/L2/L3 expectation.

## 8. Historical source

Original mixed document: docs/history/p1-summary-bank.md (frozen, read-only reference).
Split executed: 2026-05-23 per CANON-AUDIT-REPORT.md Weak Point #2.
