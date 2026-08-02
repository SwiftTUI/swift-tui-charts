# Development

## Toolchain

Use `swiftly` to manage Swift. The pinned version is in `.swift-version`.
Always build and run tests through `swiftly run swift ...`.

## Gates

- `tools/bazel/native_gate.sh` — runs `swift test` and the public API baseline
  check. The repository CI runs this gate. The SwiftTUI org root runs it as
  `@swift_tui_charts//:native_gate`.
- `.github/workflows/test.yml` — fresh-clone verification on macOS and
  Linux, a Linux release build, and a `wasm32-wasi` cross-compile of the
  `SwiftTUICharts` target.

## Rendered-text fixtures

`ChartRenderedTextFixtureTests` compares every chart case against
checked-in fixtures for five terminal capability profiles. Treat fixture
changes as evidence, not housekeeping. A fixture diff means that user-visible
output changed. Put the diff in a reviewed commit that explains the change.

To re-record after an intentional change:

```bash
Scripts/record_rendered_text_fixtures.sh
```

`Scripts/check_rendered_text_fixture_matrix.sh` enforces that every fixture
directory carries exactly the supported profile set.

## Public API baseline

`docs/.public-api-baseline.txt` enumerates the public surface. The native
gate fails on drift. For an intentional API change, regenerate the baseline
with `Scripts/generate_public_api_baseline.sh`. Commit the baseline diff with
the API change.

## Releases

Versions are lockstep with the SwiftTUI org (`swift-tui`, `swift-tui-web`,
and examples). The manifest pins the matching `swift-tui` tag with `exact:`.
The org coordination root controls the release sequence and pin checks.
