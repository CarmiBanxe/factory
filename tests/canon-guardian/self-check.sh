#!/usr/bin/env bash
# self-check.sh — run guardian checks against the CURRENT WORKING TREE (repo root),
# mirroring canon-guardian.yml CI. Use before pushing canon changes.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=lib-guardian-checks.sh
source "$SCRIPT_DIR/lib-guardian-checks.sh"
cd "$REPO_ROOT"
if run_guardian_checks; then
  echo "SELF-CHECK PASS: working tree satisfies canon-guardian checks."
  exit 0
else
  echo "SELF-CHECK FAIL: working tree violates one or more canon-guardian checks (see above). Fix before push."
  exit 1
fi
