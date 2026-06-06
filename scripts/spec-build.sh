#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAP_FILE="$ROOT_DIR/config/spec-repo-map.tsv"
TMP_DIR="${TMPDIR:-/tmp}/spec-build.$$"
DRY_RUN=0; SPEC_REF=""; SPEC_PATH=""; SPEC_FAMILY=""
TARGET_REPO_SLUG=""; OUTPUT_TYPE=""; ALLOWED_SCOPE=""; NOTES=""
TARGET_REPO_NAME=""; TARGET_REPO_DIR=""; RIGHT_REPO_DIR="${HOME}/banxe-architecture"; BRANCH=""
cleanup() { log "TMP_DIR preserved for diagnostics: $TMP_DIR"; }; trap cleanup EXIT
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
    *exchangeport*contract*spec*.md) SPEC_FAMILY="exchangeport-contract";;
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
  git -C "$TARGET_REPO_DIR" fetch origin --quiet || fail "fetch origin failed"
  git -C "$TARGET_REPO_DIR" rev-parse --verify "origin/$d" >/dev/null 2>&1 || fail "origin/$d not found after fetch"
  git -C "$TARGET_REPO_DIR" checkout -B "$BRANCH" "origin/$d" --quiet; log "On $BRANCH (base: origin/$d)"
}
preflight_target_clean() {
  log "Pre-flight — target repo cleanliness"
  local d dirty n local_sha origin_sha
  dirty="$(git -C "$TARGET_REPO_DIR" status --porcelain)"
  if [[ -n "$dirty" ]]; then
    n="$(printf '%s\n' "$dirty" | wc -l | tr -d ' ')"
    log "WARN: target working tree is DIRTY ($n file(s)) — PR base may be unclean (NOT auto-fixed)"
  fi
  d="$(gh -R "$TARGET_REPO_SLUG" repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null || echo main)"
  local_sha="$(git -C "$TARGET_REPO_DIR" rev-parse --verify "$d" 2>/dev/null || true)"
  origin_sha="$(git -C "$TARGET_REPO_DIR" rev-parse --verify "origin/$d" 2>/dev/null || true)"
  if [[ -n "$local_sha" && -n "$origin_sha" && "$local_sha" != "$origin_sha" ]]; then
    log "WARN: local '$d' diverges from 'origin/$d' (local=${local_sha:0:7} origin=${origin_sha:0:7}) — PR base may be unclean (NOT auto-fixed)"
  fi
  log "Pre-flight cleanliness check done"
}
run_agent() {
  local name="$1" pf="$2" of="$3" cwd="$4"
  [[ -f "$pf" ]] || fail "Prompt missing: $pf"
  if [[ $DRY_RUN -eq 1 ]]; then
    { echo "DRY_RUN agent=$name cwd=$cwd scope=$ALLOWED_SCOPE"
      case "$name" in architect) echo "READY";; reviewer) echo "APPROVED FOR CANON-GUARDIAN";; canon-guardian) echo "PASS";; factory-watchdog) echo "GREEN";; esac
    } > "$of"; return 0; fi
  ( cd "$cwd" && claude --agent "$name" -p "$(cat "$pf")" ) > "$of" || fail "Agent failed: $name"
}
mk_arch() { { echo "Run architect. family=$SPEC_FAMILY target=$TARGET_REPO_SLUG output=$OUTPUT_TYPE scope=$ALLOWED_SCOPE"; echo "Return only READY or NOT READY per your contract."; echo "SPEC:"; cat "$TMP_DIR/spec.md"; } > "$TMP_DIR/a.prompt"; }
mk_dev()  {
  { echo "Run developer. target_dir=$TARGET_REPO_DIR output=$OUTPUT_TYPE"
    echo "HARD: write ONLY within scope: $ALLOWED_SCOPE. No git ops."
    echo "DO NOT TOUCH any file outside: $ALLOWED_SCOPE."
    echo "ABSOLUTE BAN: no edits of any kind outside allowed scope (imports, __all__, formatting, whitespace, incidental refactors)."
    echo "If you believe an out-of-scope file should change, do NOT edit it; instead, keep all code edits strictly inside the allowed scope only."
    echo "SPEC:"
    cat "$TMP_DIR/spec.md"
    echo "ARCHITECT:"
    cat "$TMP_DIR/a.out"
  } > "$TMP_DIR/d.prompt"
}
mk_rev()  { { echo "Run reviewer. scope=$ALLOWED_SCOPE"; echo "Return only APPROVED FOR CANON-GUARDIAN or REJECTED per your contract."; echo "SPEC:"; cat "$TMP_DIR/spec.md"; echo "DEVELOPER:"; cat "$TMP_DIR/d.out"; } > "$TMP_DIR/r.prompt"; }
mk_guard(){ { echo "Run canon-guardian. scope=$ALLOWED_SCOPE"; echo "Return only PASS or FAIL with reason."; echo "ARCHITECT:"; cat "$TMP_DIR/a.out"; echo "REVIEWER:"; cat "$TMP_DIR/r.out"; } > "$TMP_DIR/g.prompt"; }
scope_match_file() {
  # Returns 0 if $1 matches any ALLOWED_SCOPE pattern (same semantics as enforce_scope/Gate B).
  local f="$1" p prefix; local IFS=','
  read -ra _patterns <<< "$ALLOWED_SCOPE"; unset IFS
  for p in "${_patterns[@]}"; do
    prefix="${p%%\**}"; prefix="${prefix%/}"
    if [[ "$p" == *'**' ]]; then
      [[ "$f" == "$prefix"/* ]] && return 0
    elif [[ "$p" == *'*' ]]; then
      [[ "$f" == "$prefix"/* && "${f#"$prefix"/}" != */* ]] && return 0
    else
      [[ "$f" == "$p" ]] && return 0
    fi
  done
  return 1
}
enforce_scope() {
  log "Scope hard-check (Gate B): $ALLOWED_SCOPE"
  [[ $DRY_RUN -eq 1 ]] && { log "DRY-RUN: scope check skipped"; return 0; }
  local current; current="$(git -C "$TARGET_REPO_DIR" status --porcelain | awk '{print $2}' | sort)"
  local changed
  if [[ -f "$TMP_DIR/baseline.files" ]]; then
    changed="$(comm -13 "$TMP_DIR/baseline.files" <(printf '%s\n' "$current"))"
  else
    changed="$current"
  fi
  [[ -n "$changed" ]] || fail "No changes produced by developer"
  local IFS=','; read -ra patterns <<< "$ALLOWED_SCOPE"; unset IFS
  local f ok p prefix
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    ok=0
    for p in "${patterns[@]}"; do
      prefix="${p%%\**}"; prefix="${prefix%/}"
      if [[ "$p" == *'**' ]]; then
        [[ "$f" == "$prefix"/* ]] && { ok=1; break; }
      elif [[ "$p" == *'*' ]]; then
        [[ "$f" == "$prefix"/* && "${f#"$prefix"/}" != */* ]] && { ok=1; break; }
      else
        [[ "$f" == "$p" ]] && { ok=1; break; }
      fi
    done
    [[ $ok -eq 1 ]] || fail "Gate B: out-of-scope file: $f (allowed: $ALLOWED_SCOPE)"
  done <<< "$changed"
  log "Scope OK"
}
stage1_architect() { log "STAGE 1 — architect"; mk_arch; run_agent architect "$TMP_DIR/a.prompt" "$TMP_DIR/a.out" "$ROOT_DIR"; grep -qi "READY" "$TMP_DIR/a.out" && ! grep -qi "NOT READY" "$TMP_DIR/a.out" || fail "Architect not READY"; }
stage2_developer() {
  log "STAGE 2 — developer"
  git -C "$TARGET_REPO_DIR" status --porcelain | awk '{print $2}' | sort > "$TMP_DIR/baseline.files"
  mk_dev; run_agent developer "$TMP_DIR/d.prompt" "$TMP_DIR/d.out" "$TARGET_REPO_DIR"
}
stage3_reviewer() { log "STAGE 3 — reviewer"; mk_rev; run_agent reviewer "$TMP_DIR/r.prompt" "$TMP_DIR/r.out" "$TARGET_REPO_DIR"; grep -qi "APPROVED FOR CANON-GUARDIAN" "$TMP_DIR/r.out" || fail "Reviewer not approved"; }
stage4_watchdog() {
  log "STAGE 4 — factory-watchdog (bank-project gate: semgrep fintech-rules + ruff)"
  [[ -f "$ROOT_DIR/quality-core/.claude/agents/factory-watchdog.md" ]] || fail "Missing agent: factory-watchdog.md"
  if [[ $DRY_RUN -eq 1 ]]; then log "DRY-RUN: watchdog checks skipped (would gate $TARGET_REPO_DIR)"; echo "GREEN" > "$TMP_DIR/g.out"; return 0; fi
  local rules="$ROOT_DIR/quality-core/semgrep/fintech-rules.yml"
  [[ -f "$rules" ]] || fail "fintech-rules.yml not found: $rules"
  require_cmd semgrep; require_cmd ruff
  # Проверяем ТОЛЬКО сгенерированные in-scope файлы в target
  log "watchdog: ruff check (in-scope)"
  ( cd "$TARGET_REPO_DIR" && ruff check $ALLOWED_SCOPE ) || fail "Watchdog RED: ruff findings in scope"
  log "watchdog: semgrep fintech-rules (ERROR severity)"
  ( cd "$TARGET_REPO_DIR" && semgrep --config "$rules" --error --quiet $ALLOWED_SCOPE ) || fail "Watchdog RED: semgrep fintech-rules findings"
  echo "GREEN" > "$TMP_DIR/g.out"
  log "Stage 4 GREEN (factory-watchdog)"
}
stage4_route() {
  case "$OUTPUT_TYPE" in
    contract-code|service-code) stage4_watchdog;;
    *) stage4_guardian;;
  esac
}

stage4_guardian() { log "STAGE 4 — canon-guardian"; mk_guard; run_agent canon-guardian "$TMP_DIR/g.prompt" "$TMP_DIR/g.out" "$ROOT_DIR"; grep -qi "PASS" "$TMP_DIR/g.out" && ! grep -qi "FAIL" "$TMP_DIR/g.out" || fail "Guardian not PASS"; }
stage5_branch_pr() {
  log "STAGE 5 — branch + PR"
  if [[ $DRY_RUN -eq 1 ]]; then log "DRY-RUN complete | would target $TARGET_REPO_SLUG branch $BRANCH"; return 0; fi
  log "STAGE 5 — staging in-scope files only: $ALLOWED_SCOPE"
  local f
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    if scope_match_file "$f"; then
      git -C "$TARGET_REPO_DIR" add -- "$f"
    else
      log "STAGE 5 — skip out-of-scope dirty file (untouched): $f"
    fi
  done < <(git -C "$TARGET_REPO_DIR" status --porcelain | awk '{print $2}')
  git -C "$TARGET_REPO_DIR" diff --cached --quiet && fail "No in-scope staged changes"
  git -C "$TARGET_REPO_DIR" -c user.email="factory@banxe.local" -c user.name="BANXE Factory" commit -m "feat(spec-build): ${SPEC_FAMILY} from SPEC" --quiet
  git -C "$TARGET_REPO_DIR" push -u origin "$BRANCH"
  local d; d="$(gh -R "$TARGET_REPO_SLUG" repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null || echo main)"
  gh -R "$TARGET_REPO_SLUG" pr create --base "$d" --head "$BRANCH" --title "feat(spec-build): ${SPEC_FAMILY} from SPEC" --body "Generated by spec-build. SPEC: ${SPEC_PATH}. Scope: ${ALLOWED_SCOPE}. PR-only." || fail "PR create failed"
  log "REAL PR done | $TARGET_REPO_SLUG | $BRANCH"
}
main() {
  parse_args "$@"; infer_spec_family; load_mapping; preflight_agents
  stage0_readiness; fetch_spec_to_tmp; prepare_target_branch
  stage1_architect; preflight_target_clean; stage2_developer; enforce_scope
  stage3_reviewer; stage4_route; stage5_branch_pr
  log "DONE — $SPEC_FAMILY mode=$([[ $DRY_RUN -eq 1 ]] && echo dry-run || echo real)"
}
main "$@"
