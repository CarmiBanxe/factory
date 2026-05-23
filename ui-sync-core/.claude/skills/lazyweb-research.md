---
name: lazyweb-research
description: Evidence-based UI research layer for factory/ui-sync-core. Uses Lazyweb only for reference discovery, pattern extraction, anti-pattern detection, and design rationale. Never modifies canonical UI artifacts directly.
allowed-tools: Read, WebFetch, Grep, Glob
model: sonnet
---

# Lazyweb Research Skill

## Purpose

Use Lazyweb as a **research-only design layer** for `factory/ui-sync-core`.

This skill exists to improve design quality by grounding UI decisions in real product references, not in agent taste or improvised aesthetics.

Lazyweb is allowed to:
- discover relevant reference screens;
- extract design patterns and anti-patterns;
- summarize recurring layout structures;
- identify visual density, navigation patterns, onboarding patterns, dashboard composition patterns;
- produce a short design-research brief for the next generation step.

Lazyweb is **not** allowed to:
- generate canonical code directly;
- overwrite generated components;
- modify design tokens;
- modify shared props contracts;
- change Storybook conventions;
- bypass typecheck, parity, or factory-watchdog controls;
- become a second source of truth.

## Canonical Position

Canonical ownership remains:

- `factory/ui-sync-core` = canonical source for UI generation behavior
- `factory/quality-core` = canonical source for quality controls
- `factory-watchdog` = canonical source for enforcement and drift detection

Lazyweb is only an **advisory research input**.

Its output may influence:
- `design.md`
- theme notes
- layout recommendations
- anti-pattern lists
- redesign hypotheses

Its output must **not** be treated as a canonical artifact until translated through the normal factory pipeline.

## When To Use

Use this skill only in these situations:

1. Before designing a new web-facing flow or page
   - onboarding
   - dashboard
   - pricing
   - landing page
   - settings
   - admin panel
   - KYC/KYB flow
   - transaction/history screen

2. Before redesigning an existing web-facing surface

3. Before visual refactors where the goal is:
   - reduce AI-slop appearance
   - improve layout quality
   - improve clarity or conversion
   - improve information density
   - align with real-world product patterns

4. During audit of a weak or generic UI proposal

Do **not** use this skill for:
- backend-only changes
- repo adapter work
- token regeneration
- parity validation
- type errors
- contract/schema changes without visual scope
- React Native-only implementation tasks unless a web reference study is explicitly needed

## Mandatory Rules

1. Lazyweb is a **research layer only**.
2. Never copy a reference literally.
3. Never reproduce a branded layout or proprietary visual identity.
4. Never treat references as implementation instructions.
5. Always extract abstractions:
   - structure
   - hierarchy
   - density
   - navigation pattern
   - CTA placement
   - empty-state pattern
   - table/card/chart composition
6. Convert references into a **design brief**, not directly into code.
7. Any implementation must still go through:
   - ui-sync generation logic
   - shared props validation
   - token discipline
   - web/mobile parity rules
   - stories conventions
   - typecheck
   - factory-watchdog checks

## Research Workflow

### Step 1 — Define research target

State the exact UI problem in one sentence:
- what surface is being designed,
- for which user,
- with which product goal.

Example:
"Research references for a fintech dashboard home screen for SMB operators who need balances, recent transactions, alerts, and quick actions."

### Step 2 — Query Lazyweb

Search for references by:
- screen type
- product category
- platform
- interaction model
- layout pattern

Example target categories:
- dashboard
- onboarding
- finance
- admin
- SaaS
- analytics
- pricing
- settings
- transaction history

### Step 3 — Extract patterns

From the retrieved references, extract only reusable signals:

- information hierarchy
- page macrostructure
- nav pattern
- section order
- action placement
- KPI arrangement
- chart/table/card balance
- form progression
- empty-state strategy
- error-state treatment
- visual density
- whitespace rhythm

### Step 4 — Extract anti-patterns

Explicitly list what should be avoided:
- generic AI-looking hero patterns
- oversized empty whitespace without purpose
- decorative gradients without semantic role
- low-density dashboards
- duplicated CTAs
- unclear primary action
- inconsistent card hierarchy
- poor scanability
- overdesigned metric blocks

### Step 5 — Produce design brief

Output a compact brief with these sections:

- Objective
- Reference pattern summary
- Anti-pattern summary
- Recommended macrostructure
- Recommended density level
- Recommended CTA strategy
- Recommended token usage constraints
- Risks to parity or drift
- Safe next implementation step

## Required Output Format

Every Lazyweb research run must end with this exact structure:

### Lazyweb Research Brief

**UI Surface:**
<name>

**Goal:**
<what the surface must achieve>

**References Reviewed:**
- <reference type 1>
- <reference type 2>
- <reference type 3>

**Observed Patterns:**
- <pattern 1>
- <pattern 2>
- <pattern 3>
- <pattern 4>

**Observed Anti-Patterns:**
- <anti-pattern 1>
- <anti-pattern 2>
- <anti-pattern 3>

**Recommended Macrostructure:**
<recommended page or screen structure>

**Recommended Density:**
<low / medium / high + why>

**Recommended CTA Model:**
<primary action logic>

**Token / Parity Constraints:**
- Must not introduce token drift
- Must remain compatible with shared props model
- Must preserve web/mobile parity where applicable
- Must not bypass stories or typecheck

**Decision:**
<Proceed / Revise / Reject>

**Safe Next Step:**
<one atomic next step for ui-sync or design planning>

## Hard Prohibitions

Never do any of the following under this skill:

- edit `apps/web` directly;
- edit `apps/mobile` directly;
- edit generated component code;
- edit `config/design-tokens/*`;
- edit `tokens.rn.ts`;
- edit `style-dictionary.config.json`;
- invent new canonical UI rules outside `factory/ui-sync-core`;
- approve visual drift just because a reference "looks better";
- skip parity because the web result is visually stronger;
- introduce a second design source of truth.

## Decision Policy

### GREEN
Use Lazyweb findings as advisory input for a design brief only.

### AMBER
Use findings cautiously when references are strong but parity/token implications are unclear.

### RED
Reject Lazyweb-driven direction if it:
- conflicts with shared props;
- introduces token drift;
- encourages web-only divergence;
- pushes literal imitation of references;
- bypasses factory generation and validation flow.
