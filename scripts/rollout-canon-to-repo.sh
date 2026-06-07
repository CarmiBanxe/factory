#!/usr/bin/env bash
# rollout-canon-to-repo.sh — Factory Canon rollout (C4 v2, downstream-mirror)
#
# Pins the Factory canon REFERENCE copies into a downstream bank repository at a
# specific Factory version, plus a LIGHTWEIGHT mirror-check workflow.
# Does NOT distribute factory-level canon-guardian (which needs fixtures/run.sh).
#
# Usage:
#   ./rollout-canon-to-repo.sh <target-repo-slug> [--version vX.Y.Z] [--dry-run]
#
# Requirements: gh (authenticated, push access to target), git.

set -euo pipefail

TARGET="${1:-}"
VERSION=""
DRY_RUN=0
shift || true
while [ $# -gt 0 ]; do
  case "$1" in
    --version) VERSION="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [ -z "$TARGET" ]; then
  echo "ERROR: target repo slug required (e.g. CarmiBanxe/banxe-payment-core)" >&2
  exit 2
fi

FACTORY_ROOT="$(git -C "$(dirname "$0")/.." rev-parse --show-toplevel)"
cd "$FACTORY_ROOT"
if [ -z "$VERSION" ]; then
  VERSION="$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")"
fi
echo "== Factory rollout (downstream-mirror C4 v2) =="
echo "Factory root : $FACTORY_ROOT"
echo "Factory ver  : $VERSION"
echo "Target repo  : $TARGET"
echo "Dry run      : $DRY_RUN"

# Reference controlled copies ONLY (no factory-level guardian / fixtures).
CONTROLLED_FILES=(
  "CANON.md"
  ".clauderules"
  "docs/canon/CANON-TOPOLOGY.md"
  "docs/canon/OVERRIDES.md"
  "docs/canon/MODULES.md"
)

for f in "${CONTROLLED_FILES[@]}"; do
  [ -f "$f" ] || { echo "ERROR: controlled file missing in factory: $f" >&2; exit 1; }
done

# Role-anchor (separate artifact, NOT a controlled canon copy): downstream bank
# repos are Central-zone, so the Central anchor lands as TERMINAL-ROLE.md in root.
ROLE_ANCHOR_SRC="role-anchors/TERMINAL-ROLE-CENTRAL.md"
ROLE_ANCHOR_DEST="TERMINAL-ROLE.md"
[ -f "$ROLE_ANCHOR_SRC" ] || { echo "ERROR: role-anchor missing in factory: $ROLE_ANCHOR_SRC" >&2; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
BRANCH="canon-pin/$VERSION"
# Resolve target default branch (main/master/other)
if [ "$DRY_RUN" -eq 1 ]; then
  BASE_BRANCH="main"
else
  BASE_BRANCH="$(gh repo view "$TARGET" --json defaultBranchRef --jq '.defaultBranchRef.name')"
fi

echo "== Cloning target =="
if [ "$DRY_RUN" -eq 1 ]; then
  echo "[dry-run] gh repo clone $TARGET"
else
  gh repo clone "$TARGET" "$WORK/repo" -- --depth 1
fi

echo "== Copying reference controlled copies =="
for f in "${CONTROLLED_FILES[@]}"; do
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "[dry-run] copy $f -> $TARGET/$f"
  else
    mkdir -p "$WORK/repo/$(dirname "$f")"
    cp "$FACTORY_ROOT/$f" "$WORK/repo/$f"
  fi
done

echo "== Copying role-anchor (Central) =="
if [ "$DRY_RUN" -eq 1 ]; then
  echo "[dry-run] copy $ROLE_ANCHOR_SRC -> $TARGET/$ROLE_ANCHOR_DEST"
else
  cp "$FACTORY_ROOT/$ROLE_ANCHOR_SRC" "$WORK/repo/$ROLE_ANCHOR_DEST"
fi

PIN_FILE=".factory-canon-version"
MIRROR_WF=".github/workflows/canon-mirror-check.yml"

if [ "$DRY_RUN" -eq 1 ]; then
  echo "[dry-run] write $PIN_FILE = $VERSION"
  echo "[dry-run] generate lightweight $MIRROR_WF"
  echo "[dry-run] base branch auto-detected (main/master)"
  echo "[dry-run] remove stale factory-guardian workflows if present"
  echo "[dry-run] branch $BRANCH, commit, push, PR"
  echo "== Dry run complete. No changes made to $TARGET. =="
  exit 0
fi

echo "$VERSION" > "$WORK/repo/$PIN_FILE"

# Lightweight downstream mirror-check: verifies presence + version pin only.
mkdir -p "$WORK/repo/.github/workflows"
cat > "$WORK/repo/$MIRROR_WF" <<'WF_EOF'
name: Canon Mirror Check
on:
  pull_request:
    paths:
      - 'CANON.md'
      - '.clauderules'
      - '.factory-canon-version'
      - 'docs/canon/**'
  push:
    branches: [main]
permissions:
  contents: read
jobs:
  mirror-check:
    name: Canon mirror presence + version pin
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Verify canon mirror integrity
        run: |
          set -euo pipefail
          test -s .factory-canon-version || { echo "::error::.factory-canon-version missing or empty"; exit 1; }
          test -s CANON.md || { echo "::error::CANON.md missing or empty"; exit 1; }
          test -s .clauderules || { echo "::error::.clauderules missing or empty"; exit 1; }
          ver="$(cat .factory-canon-version)"
          echo "Pinned Factory canon version: $ver"
          grep -q "Decision-Making Axiom" CANON.md || { echo "::error::CANON.md missing Decision-Making Axiom"; exit 1; }
          echo "Canon mirror OK."
WF_EOF

cd "$WORK/repo"
# Remove stale factory-level guardian (downstream uses mirror-check only)
for stale in .github/workflows/canon-guardian.yml .github/workflows/canon-guardian-regression.yml; do
  [ -f "$stale" ] && git rm -f "$stale" || true
done
git checkout -b "$BRANCH"
git add "${CONTROLLED_FILES[@]}" "$ROLE_ANCHOR_DEST" "$PIN_FILE" "$MIRROR_WF"
git commit -m "chore(canon): pin Factory canon $VERSION (downstream mirror)

Distributes Factory reference controlled copies + lightweight
canon-mirror-check workflow, pinned at Factory $VERSION.
Does not include factory-level guardian (fixtures live in factory only).
Generated by factory/scripts/rollout-canon-to-repo.sh."
git push -u origin "$BRANCH"
gh pr create \
  --base "$BASE_BRANCH" \
  --head "$BRANCH" \
  --title "chore(canon): pin Factory canon $VERSION (downstream mirror)" \
  --body "Automated canon mirror rollout from factory $VERSION. Distributes reference controlled copies + lightweight mirror-check workflow."

echo "== Rollout PR created for $TARGET at $VERSION =="
