#!/usr/bin/env sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
output_path=".build-docs"
hosting_base_path="docs/charts"

usage() {
  cat <<'USAGE'
Usage: Scripts/build_docc_archive.sh [--output-path PATH] [--hosting-base-path PATH]

Builds the SwiftTUICharts DocC archive for static hosting. The SwiftTUI site
mounts this archive at /docs/charts.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
  --output-path)
    output_path=$2
    shift 2
    ;;
  --hosting-base-path)
    hosting_base_path=$2
    shift 2
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    >&2 echo "Unknown argument: $1"
    >&2 echo ""
    usage >&2
    exit 1
    ;;
  esac
done

cd "$repo_root"

rm -rf "$output_path"

if command -v swiftly >/dev/null 2>&1; then
  swift() { command swiftly run swift "$@"; }
fi

swift package \
  --allow-writing-to-directory "$output_path" \
  generate-documentation \
  --target SwiftTUICharts \
  --transform-for-static-hosting \
  --hosting-base-path "$hosting_base_path" \
  --output-path "$output_path"
