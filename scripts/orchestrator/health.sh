#!/usr/bin/env bash
# health.sh - R7 gateway/node health probe for the orchestration engine.
# Read-only: performs NO repo mutation. Used by Gate A (R7) and scheduler (R6).
# Canon refs: COMPUTE-TOPOLOGY.md (§1.bis single seam), S3-IMPL.md R6/R7.
set -euo pipefail

# --- fail-closed role guard (canon F6: no silent skip) ---
ROLE_ANCHOR="${ROLE_ANCHOR:-.TERMINAL-ROLE}"
if [[ ! -f "$ROLE_ANCHOR" ]]; then
  echo "FATAL: role anchor '$ROLE_ANCHOR' missing - refusing to run (fail-closed)" >&2
  exit 1
fi

GATEWAY_URL="${LITELLM_URL:-http://127.0.0.1:4000}"
DRY_RUN="${DRY_RUN:-0}"

# probe_gateway: §1.bis seam must be reachable AND have a connected DB.
# Returns 0 if healthy, 1 otherwise. Never bypasses to :11434 (fail-closed).
probe_gateway() {
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "DRY_RUN: would probe gateway $GATEWAY_URL/health"
    return 0
  fi
  local body
  body="$(curl -fsS --max-time 5 "$GATEWAY_URL/health" 2>/dev/null || true)"
  if [[ -z "$body" ]]; then
    echo "R7 FAIL: gateway $GATEWAY_URL unreachable" >&2
    return 1
  fi
  # AC7.1: 'No connected db' => fail-closed, do NOT route around the seam.
  if grep -qi "No connected db" <<<"$body"; then
    echo "R7 FAIL: gateway reports 'No connected db' (LiteLLM Postgres down) - fail-closed" >&2
    return 1
  fi
  echo "R7 OK: gateway healthy"
  return 0
}

# probe_model: R6 - is the target model loaded on its layer node?
# Reads node base URL from arg; checks Ollama /api/ps for the model name.
# AC6.2: a not-loaded model yields non-zero so scheduler can DEFER (not fail).
probe_model() {
  local node_url="$1" model="$2"
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "DRY_RUN: would check $model loaded on $node_url"
    return 0
  fi
  local ps
  ps="$(curl -fsS --max-time 5 "$node_url/api/ps" 2>/dev/null || true)"
  if grep -q "$model" <<<"$ps"; then
    echo "R6 OK: model '$model' loaded on $node_url"
    return 0
  fi
  echo "R6 DEFER: model '$model' NOT loaded on $node_url" >&2
  return 2
}

main() {
  local cmd="${1:-gateway}"
  case "$cmd" in
    gateway) probe_gateway ;;
    model)   probe_model "${2:?node_url}" "${3:?model}" ;;
    *) echo "usage: health.sh {gateway|model <node_url> <model>}" >&2; exit 1 ;;
  esac
}
main "$@"
