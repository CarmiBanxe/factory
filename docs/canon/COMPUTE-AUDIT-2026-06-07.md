# COMPUTE CAPACITY AUDIT — 2026-06-07

**From:** Central
**To:** Terminal A (factory)
**Method:** read-only diagnostic (Legion shell + evo1/evo2 Ollama API :11434)
**Status:** Canonical evidence artifact. Referenced by OPEN-GAPS.md (G1–G6).
**Verbatim:** This document preserves the audit as delivered. Do not paraphrase; cite it.

---

## v1 — initial diagnostic (Legion-only access)

### 1. LEGION (factory)
- HW: 20 CPU, 56 GB RAM (WSL2 cap; canon says 23 GiB — STALE, must update), RTX 4070 Laptop 8 GB VRAM.
- Load: RAM 4.2/54 GiB, GPU util 15%, VRAM 450/8188 MiB — IDLE.
- Ollama: qwen2.5-coder:14b-banxe-factory (9 GB) + qwen2.5-coder:7b (4.7 GB).
- `ollama ps` empty — no model loaded in VRAM.

### 2. EVO1 (infra/services) — from canon
- HW: 128 GB RAM. Intent: several baseline/small models for services.
- Direct audit IMPOSSIBLE: Tailscale SSH closed by ACL, ping by name fails (tailnet banxe-nucbox-evo-x1, 100.68.102.48).

### 3. EVO2 (heavy model) — from canon + indirect
- HW: 128 GB RAM, 1.9 TB SSD, AMD GPU. Model: qwen3:235b (quantized).
- CRITICAL: GPU stack (ROCm/Vulkan) NOT functioning → qwen3:235b runs CPU-only.
- evo2 (100.99.208.21) active, polls Legion LiteLLM /metrics — network link present.

### 4. ORCHESTRATION (LiteLLM) — BROKEN
- LiteLLM gateway on :4000 running (pid 175), config v2 rich: factory-fast/mid/heavy/coder, project-mid/project-reason, reasoning-235b, qwen3-30b, glm-4, gpt-oss-20b, etc.
- All chat requests → "No connected db". LiteLLM needs Postgres (keys/logs), DB not connected.
- Canonical litellm-v2 user-service stopped since 2026-05-22; a different instance without DB is running.
- ⇒ Single-seam routing (§1.bis) is DEAD.

### 5. KEY FINDING — intent vs reality gap
- Factory (spec-build.sh) calls `claude --` (Claude Code / Anthropic), NOT the local LLM stack.
- All 6 ports + 4 ADRs in the current session were produced through Claude.
- Local coding stack (qwen2.5-coder 14B/7B on Legion) — NOT USED (dead weight).
- evo1/evo2 models — NOT engaged by factory in code production.
- Legion GPU idle; evo2 235b on CPU burns resources wastefully.
- "Orchestration" de facto = manual `claude -p` feeds; local LLM layer bypassed.

### 6. EFFICIENCY
- Legion: LOW. 8 GB VRAM does not fit 14B coder fully; models not loaded; factory uses Claude anyway.
- evo1: UNKNOWN (no access), likely underutilized.
- evo2: VERY LOW. 235b on CPU = slow and inefficient; AMD GPU unused.
- LiteLLM: NOT WORKING as orchestrator (No DB).

### 7. RECOMMENDATIONS
- P0 (D1): Strategic decision — factory on Claude or on local LLM? Currently local stack is bought/configured but unused. Either switch spec-build to local (factory-coder via LiteLLM), or accept Claude as primary and stop holding local idle.
- P0: Fix LiteLLM (connect Postgres / DATABASE_URL). Raise canonical litellm-v2, kill duplicate instance.
- P1: Restore GPU stack on evo2 (ROCm/Vulkan). 235b on CPU unacceptable. Canon already contains this action.
- P1: Legion VRAM (8 GB) is a bottleneck for 14B. Either use 7B-coder (fits), offload coding to a node with larger GPU, or accept Claude.
- P2: Update canon HW Baseline (Legion 56 GB, not 23 GiB — WSL2 cap changed).
- P2: Open read-only monitoring of evo1/evo2 for Central/audit (SSH ACL closed; metrics flow evo2 → Legion exists, no reverse path).

---

## v2 — direct data (Ollama API :11434 reachable on both evo nodes)

Limitation "no access to evo" lifted: SSH closed, but Ollama API :11434 is open on both.

### 1. LEGION (factory)
- Same as v1. Coding stack on Legion = dead weight (factory uses Claude).

### 2. EVO1 (infra/services) — 100.68.102.48, Ollama 0.22.1
- 9 models: llama3.3:70b (42.5 GB), qwen3.5:35b (23.9 GB), qwen3:30b-a3b (18.6 GB), qwen3-coder-next:q4_K_M (51.7 GB), qwen2.5-coder:7b, qwen3:4b, qwen3.5, gpt-oss-20b, glm-4.7.
- LIVE LOAD: qwen3:30b-a3b in memory, size_vram=25.2 GB fully on GPU (efficient).
- Intent "several models" CONFIRMED; evo1 actually works.

### 3. EVO2 (heavy model) — 100.99.208.21, Ollama 0.22.1
- 11 models: same 9 as evo1 (DUPLICATES) + qwen3:235b-a22b-banxe (142 GB) + qwen3:235b-a22b (142 GB) + qwen2.5:0.5b.
- LIVE LOAD: NONE. Heavy 235b NOT in memory now.
- Intent "one heavy model" — the model exists (235b), but is NOT RUNNING currently.
- Clarification to v1: "235b on CPU" was from canon; right now 235b is not loaded at all. AMD GPU/ROCm status remains open until 235b is loaded and inspected.

### 4. ORCHESTRATION (LiteLLM on Legion :4000) — BROKEN
- Same diagnosis as v1: rich config, evo2 sends /metrics, but "No connected db".
- Canonical litellm-v2 stopped since 2026-05-22; non-DB instance active.
- ⇒ Single-seam §1.bis NOT functioning. Agents hitting Ollama :11434 directly work only because the gateway is not in the path.

### 5. KEY FINDINGS
- A. GAP: factory on Claude; local stack (Legion coder + evo coder-next 51.7 GB) idle for coding. qwen3-coder-next:q4_K_M is on BOTH evo nodes but the factory does not use it.
- B. evo2 235b not loaded — most expensive resource (142 GB model) idle.
- C. DUPLICATION: 6 models on both evo1 and evo2 (disk). Including coder-next 51.7 GB ×2 and llama70b 42.5 GB ×2 — ~200 GB+ of duplicates. Layering broken (evo1 = infra/small, evo2 = heavy is violated; evo1 carries 70b and coder-next).
- D. LiteLLM without DB — orchestration not working; agents go around it.

### 6. EFFICIENCY
- Legion: LOW (GPU/coder idle, factory on Claude).
- evo1: MEDIUM-GOOD (30b-a3b actually on GPU, working). Overloaded with non-tier models (70b, coder-next — these are "heavy", should live on evo2).
- evo2: LOW (235b not loaded; heavy tier idle).
- LiteLLM: NOT WORKING.

### 7. RECOMMENDATIONS
- P0 (D1) CODING STRATEGY: factory on Claude or on local. If local: switch spec-build to qwen3-coder-next:q4_K_M (51.7 GB, already on evo) via LiteLLM. If Claude: remove unused Legion coder models (9+4.7 GB) as dead weight.
- P0 FIX LiteLLM: connect Postgres (DATABASE_URL), raise canonical litellm-v2, kill duplicate non-DB instance. Without this §1.bis is dead.
- P1 MODEL TIERING: evo1 = small/mid (4b/0.5b/30b/35b/glm/gpt-oss), evo2 = heavy (235b + 70b + coder-next). Remove duplicates (~200 GB) — evict heavy from evo1.
- P1 EVO2 235b: investigate why not loaded; restore AMD GPU/ROCm (canon-action). If GPU not recoverable, reconsider whether 235b is needed at all, or qwen3-coder-next/llama70b suffices.
- P2 UPDATE canon HW Baseline: Legion 56 GB (not 23 GiB); evo1 actually carries heavy models (diverges from "infra/baseline" role).
- P2 MONITORING: Ollama API :11434 is open on evo — a regular read-only health audit (models/load/GPU) for Central without SSH is feasible.

### Residual limitation
GPU utilization on evo1/evo2 directly (nvidia/rocm-smi) not captured. Ollama API gives size_vram (indirect GPU), but not AMD GPU load on evo2. Requires either access to their metrics, or loading 235b and inspecting size_vram. Not critical for the conclusions.
