# COMPUTE-TOPOLOGY — Factory Compute Fabric

Canon version: 1.6.2 | Date: 2026-06-07 | Authority: CANON.md@69d6228
Level: 1 (operational topology, subordinate to CANON.md)
Source: Central compute audit v1 + v2 (2026-06-07, read-only)

This document codifies the ACTUAL compute fabric of the factory. It exists
because the runtime intent (model routing via a single seam) had drifted from
reality and was never committed to canon. Per the Honest Reporting principle,
this is the single source of truth for hardware, model layering, and the
orchestration seam.

## 1. HW Baseline (actual, not intent)

| Node | CPU / RAM | GPU / VRAM | Role (actual) | Tailnet |
|------|-----------|------------|---------------|---------|
| Legion (Factory) | 20 CPU / 56 GB (WSL2 cap) | RTX 4070 Laptop 8 GB | spec-build host | local |
| evo1 | 128 GB | NVIDIA (size_vram OK) | infra/mid (de-facto carries heavy too) | 100.68.102.48 |
| evo2 | 128 GB / 1.9 TB SSD | AMD (ROCm NOT functional) | heavy (235b) | 100.99.208.21 |

NOTE: prior canon recorded Legion RAM as 23 GiB. CORRECTED to 56 GB (WSL2 cap changed).

## 2. §1.bis — Single Seam (normative)

All model traffic MUST route through the LiteLLM gateway (:4000). Direct calls
to Ollama (:11434) bypassing the gateway are FORBIDDEN (fail-closed), aligned
with the CANON.md axiom that direct claude/-p execution is forbidden.
The gateway is the only sanctioned seam between agents and model nodes.

## 3. Model layering (target)

- evo1 (small/mid): qwen3:4b, qwen2.5:0.5b, qwen3:30b-a3b, qwen3.5:35b, glm-4.7, gpt-oss-20b
- evo2 (heavy): qwen3:235b-a22b, llama3.3:70b, qwen3-coder-next:q4_K_M
- Legion: spec-build host only; local coder models (14b/7b) status depends on NF-2 decision

CURRENT STATE = DRIFT: evo1 carries heavy models (70b, coder-next) that belong
on evo2; ~200 GB of duplicates exist across evo1/evo2.

## 4. Negative Factors Register (tracked action items)

| ID | Factor | Sev | Owner | Sprint | Status |
|----|--------|-----|-------|--------|--------|
| NF-1 | LiteLLM 'No connected db' — §1.bis routing dead; agents bypass to :11434 | P0 | Central | C-S1 | OPEN |
| NF-2 | spec-build calls `claude --`; local stack idle (intent/reality gap) | P0 | Central+A | C-S1 | OPEN |
| NF-3 | evo2 235b not loaded; AMD GPU/ROCm not functional | P1 | Central | C-S2 | OPEN |
| NF-4 | ~200 GB duplicate models across evo1/evo2; layer roles violated | P1 | Central | C-S2 | OPEN |
| NF-5 | Legion 8 GB VRAM cannot hold 14B coder | P1 | Central | C-S2 | OPEN |
| NF-6 | Canon HW baseline stale (Legion 23 GiB; evo1 role mismatch) | P2 | A | C-S3 | THIS DOC |
| NF-7 | No read-only monitoring of evo1/evo2 (SSH ACL closed; :11434 open) | P2 | Central | C-S3 | OPEN |
| NF-8 | §1.bis + HW baseline absent from canon (drift root cause) | P2 | A | C-S3 | THIS DOC |

## 5. Boundaries

Terminal A codifies this topology and builds engine schedulability (R6/R7).
Infra execution (Postgres for LiteLLM, ROCm on evo2, model relocation, killing
the duplicate gateway instance) is Central's domain. The engine only DETECTS
drift/health and never auto-resolves the Claude-vs-local strategic decision
(NF-2), which is a merit-based human decision.
