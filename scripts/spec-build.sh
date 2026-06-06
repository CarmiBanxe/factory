#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAP_FILE="$ROOT_DIR/config/spec-repo-map.tsv"
TMP_DIR="${TMPDIR:-/tmp}/spec-build.$$"
DRY_RUN=0; SPEC_REF=""; SPEC_PATH=""; SPEC_FAMILY=""
TARGET_REPO_SLUG=""; OUTPUT_TYPE=""; ALLOWED_SCOPE=""; NOTES=""
TARGET_REPO_NAME=""; TARGET_REPO_DIR=""; RIGHT_REPO_DIR="${HOME}/banxe-architecture"; BRANCH=""
cleanup() { rm -rf "$TMP_DIR"; }; trap cleanup EXIT
log()  { printf '[spec-build] %s\n' "$*"; }
fail() { printf '[spec-build][FAIL] %s\n' "$*" >&2; exit 1; }
require_cmd() { command -v "$1" >/dev/null 2>&1 || fail "Missing command: $1"; }
usage() { echo "Usage: spec-build.sh <spec-file-path> [--spec-ref <branch>] [--dry-run]"; }
parse_args() {
  [[ $# -ge 1 ]] || { usage; exit 1; }; SPEC_PATH="$1"; shift
  while [[ $# -gt 0 ]]; do case "$1" in
    --spec-ref) [[ $# -ge 2 ]] || fail "--spec-ref needs value"; SPEC_REF="$2"; shift 2;;
    --dry-run) DRY_RUN=1; shift;; -h|--help) usage; exit 0;;
    *) fail "Unknown arg: $1";; esac; done
}
infer_spec_family() {
  local b; b="$(basename "$SPEC_PATH" | tr '[:upper:]' '[:lower:]')"
  case "$b" in
    *wallet*contract*spec*.md) SPEC_FAMILY="walletport-contract";;
    *kyc*provider*port*spec*.md) SPEC_FAMILY="kyc-provider-port";;
    *partnerport*contract*spec*.md) SPEC_FAMILY="emi-banking-partnerport-CONTRACT";;
    *crypto*ops*subgroup*spec*.md) SPEC_FAMILY="crypto-ops-subgroup";;
    *) fail "Cannot infer spec_family from: $b";; esac
}
load_mapping() {
  [[ -f "$MAP_FILE" ]] || fail "Mapping not found: $MAP_FILE"
  local found=0
  while IFS=$'\t' read -r f slug otype scope notes; do
    [[ -z "${f:-}" || "$f" == "spec_family" ]] && continue
    if [[ "$f" == "$SPEC_FAMILY" ]]; then
      TARGET_REPO_SLUG="$slug"; OUTPUT_TYPE="$otype"; ALLOWED_SCOPE="$scope"; NOTES="$notes"; found=1; break; fi
  done < "$MAP_FILE"
  [[ $found -eq 1 ]] || fail "spec_family not in mapping: $SPEC_FAMILY"
  TARGET_REPO_NAME="${TARGET_REPO_SLUG##*/}"; TARGET_REPO_DIR="${HOME}/${TARGET_REPO_NAME}"
}
deterministic_branch() { echo "spec-build/${SPEC_FAMILY}" | tr '[:upper:]' '[:lower:]'; }
preflight_agents() {
  log "Preflight — Gate A"
  local a; for a in architect developer reviewer canon-guardian; do
    [[ -f "$ROOT_DIR/.claude/agents/${a}.md" ]] || fail "Missing agent: ${a}.md"; done
  log "Gate A OK"
}
stage0_readiness() {
  log "STAGE 0 — readiness"
  require_cmd git; require_cmd gh; require_cmd claude; require_cmd awk; require_cmd grep
  [[ -n "$SPEC_PATH" && -n "$SPEC_FAMILY" && -n "$TARGET_REPO_SLUG" && -n "$OUTPUT_TYPE" && -n "$ALLOWED_SCOPE" ]] || fail "Empty field"
  [[ $DRY_RUN -eq 0 && -n "$SPEC_REF" ]] && fail "--spec-ref only with --dry-run"
  [[ -d "$RIGHT_REPO_DIR/.git" ]] || fail "SPEC source repo not found: $RIGHT_REPO_DIR"
  [[ -d "$TARGET_REPO_DIR/.git" ]] || fail "Target not cloned: $TARGET_REPO_DIR"
  BRANCH="$(deterministic_branch)"
  if [[ $DRY_RUN -eq 0 ]]; then
    if gh -R "$TARGET_REPO_SLUG" pr list --head "$BRANCH" --json number -q '.[0].number' 2>/dev/null | grep -q '[0-9]'; then
      fail "PR already exists for $BRANCH"; fi; fi
  mkdir -p "$TMP_DIR"
  log "Mode: $([[ $DRY_RUN -eq 1 ]] && echo DRY-RUN || echo REAL) | branch: $BRANCH | target: $TARGET_REPO_SLUG"
}
fetch_spec_to_tmp() {
  log "Fetch SPEC"
  local ref="${SPEC_REF:-main}"
  git -C "$RIGHT_REPO_DIR" rev-parse --verify "$ref" >/dev/null 2>&1 || fail "SPEC ref not found: $ref"
  git -C "$RIGHT_REPO_DIR" show "${ref}:${SPEC_PATH}" > "$TMP_DIR/spec.md" 2>/dev/null || fail "SPEC not found at $ref: $SPEC_PATH"
  [[ -s "$TMP_DIR/spec.md" ]] || fail "SPEC empty"
}
prepare_target_branch() {
  log "Prepare branch"
  [[ $DRY_RUN -eq 1 ]] && { log "DRY-RUN: skip branch"; return 0; }
  local d; d="$(gh -R "$TARGET_REPO_SLUG" repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null || echo main)"
  git -C "$TARGET_REPO_DIR" fetch origin --quiet || true
  git -C "$TARGET_REPO_DIR" checkout "$d" --quiet; git -C "$TARGET_REPO_DIR" pull --ff-only --quiet || true
  git -C "$TARGET_REPO_DIR" checkout -B "$BRANCH" --quiet; log "On $BRANCH"
}
run_agent() {
  local name="$1" pf="$2" of="$3" cwd="$4"
  [[ -f "$pf" ]] || fail "Prompt missing: $pf"
  if [[ $DRY_RUN -eq 1 ]]; then
    { echo "DRY_RUN agent=$name cwd=$cwd scope=$ALLOWED_SCOPE"
      case "$name" in architect) echo "READY";; reviewer) echo "APPROVED FOR CANON-GUARDIAN";; canon-guardian) echo "PASS";; esac
    } > "$of"; return 0; fi
  ( cd "$cwd" && claude --agent "$name" -p "$(cat "$pf")" ) > "$of" || fail "Agent failed: $name"
}
mk_arch() { { echo "Run architect. family=$SPEC_FAMILY target=$TARGET_REPO_SLUG output=$OUTPUT_TYPE scope=$ALLOWED_SCOPE"; echo "Return only READY or NOT READY per your contract."; echo "SPEC:"; cat "$TMP_DIR/spec.md"; } > "$TMP_DIR/a.prompt"; }
mk_dev()  { { echo "Run developer. target_dir=$TARGET_REPO_DIR output=$OUTPUT_TYPE"; echo "HARD: write ONLY within scope: $ALLOWED_SCOPE. No git ops."; echo "SPEC:"; cat "$TMP_DIR/spec.md"; echo "ARCHITECT:"; cat "$TMP_DIR/a.out"; } > "$TMP_DIR/d.prompt"; }
mk_rev()  { { echo "Run reviewer. scope=$ALLOWED_SCOPE"; echo "Return only APPROVED FOR CANON-GUARDIAN or REJECTED per your contract."; echo "SPEC:"; cat "$TMP_DIR/spec.md"; echo "DEVELOPER:"; cat "$TMP_DIR/d.out"; } > "$TMP_DIR/r.prompt"; }
mk_guard(){ { echo "Run canon-guardian. scope=$ALLOWED_SCOPE"; echo "Return only PASS or FAIL with reason."; echo "ARCHITECT:"; cat "$TMP_DIR/a.out"; echo "REVIEWER:"; cat "$TMP_DIR/r.out"; } > "$TMP_DIR/g.prompt"; }
