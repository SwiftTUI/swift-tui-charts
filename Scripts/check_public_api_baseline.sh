#!/usr/bin/env bash
set -euo pipefail

# Verifies the committed public API baseline (docs/.public-api-baseline.txt)
# matches the built module. Fails on any unreviewed public symbol addition or
# removal. Regenerate deliberately with Scripts/generate_public_api_baseline.sh
# and include the diff in the same reviewed change.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

BASELINE="docs/.public-api-baseline.txt"
CURRENT="$("${SCRIPT_DIR}/generate_public_api_baseline.sh" --print)"

if ! diff -u "${BASELINE}" <(printf '%s\n' "${CURRENT}"); then
  echo "" >&2
  echo "check_public_api_baseline: public API drift detected." >&2
  echo "If the change is intentional and reviewed, run" >&2
  echo "  Scripts/generate_public_api_baseline.sh" >&2
  echo "and commit the updated ${BASELINE} together with the API change." >&2
  exit 1
fi

echo "check_public_api_baseline: OK ($(wc -l < "${BASELINE}" | tr -d ' ') symbols)."
