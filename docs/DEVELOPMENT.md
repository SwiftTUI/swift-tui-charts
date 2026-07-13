# Development

## Toolchain

Swift is managed with `swiftly`; the pinned version lives in
`.swift-version`. Always build and test through `swiftly run swift ...`.

## Gates

- `tools/bazel/native_gate.sh` — the repo gate CI runs: `swift test` plus the
  public API baseline check. The SwiftTUI org root runs the same script as
  `@swift_tui_charts//:native_gate`.
- `.github/workflows/test.yml` — fresh-clone verification on macOS and
  Linux, a Linux release build, and a `wasm32-wasi` cross-compile of the
  `SwiftTUICharts` target.

## Rendered-text fixtures

`ChartRenderedTextFixtureTests` compares every chart case against
checked-in fixtures for five terminal capability profiles. Treat fixture
changes as evidence, not housekeeping: a fixture diff means user-visible
output changed, and belongs in a reviewed commit that explains why.

To re-record after an intentional change:

```bash
Scripts/record_rendered_text_fixtures.sh
```

`Scripts/check_rendered_text_fixture_matrix.sh` enforces that every fixture
directory carries exactly the supported profile set.

## Public API baseline

`docs/.public-api-baseline.txt` enumerates the public surface. The native
gate fails on drift; regenerate deliberately with
`Scripts/generate_public_api_baseline.sh` and commit the diff with the API
change.

## Releases

Versions are lockstep with the SwiftTUI org (`swift-tui`, `swift-tui-web`,
examples). The manifest pins the matching `swift-tui` tag with `exact:`;
release sequencing and pin verification run from the org coordination root.
