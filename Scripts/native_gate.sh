#!/usr/bin/env bash
set -euo pipefail

# swift-tui-charts native gate: build + run the SwiftTUICharts test suite with
# SwiftPM, then verify the public API baseline. The chart library is
# platform-portable (macOS and Linux; the WASI cross-compile runs in CI), so
# unlike the SwiftUI host gate there is no platform skip. Resolves the
# `swift-tui` dependency from its public tagged release. Matches the org
# toolchain convention (swiftly-managed Swift). Run by this repo's CI and by
# the SwiftTUI org root's coordination gates.

script_source="${BASH_SOURCE[0]}"
if command -v realpath >/dev/null 2>&1; then
  script_path="$(realpath "$script_source")"
else
  script_path="$(python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$script_source")"
fi

# Structural resolution (script lives at Scripts/): the coordination overlay
# materializes this repo WITHOUT .git and nested inside the org checkout, so a
# git-toplevel lookup would escape to the wrong root.
repo_root="$(cd "$(dirname "$script_path")/.." && pwd)"

cd "$repo_root"

run_swift() {
  if command -v swiftly >/dev/null 2>&1; then
    swiftly run swift "$@"
  else
    swift "$@"
  fi
}

run_swift test

Scripts/check_public_api_baseline.sh
