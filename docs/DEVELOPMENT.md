# Development

## Toolchain

Use `swiftly` to manage Swift. The pinned version is in `.swift-version`.
Always build and run tests through `swiftly run swift ...`.

## Gates

- `Scripts/native_gate.sh`: runs `swift test` and the public API baseline
  check. The repository CI runs this gate. The SwiftTUI org root runs it as
  `//:swift_tui_charts_native_gate`.
- `.github/workflows/test.yml`: fresh-clone verification. Every push and
  pull request runs the Linux gate and a `wasm32-wasi` cross-compile of the
  `SwiftTUICharts` target. The macOS gate runs nightly (skipping itself when
  nothing has landed since its last green run), on every release tag, and
  on `workflow_dispatch`; the Linux release-configuration build runs on tags
  and dispatch only.

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

The baseline process and policy live in [PUBLIC-API.md](PUBLIC-API.md).
Regenerate with `Scripts/generate_public_api_baseline.sh` and commit the
baseline diff with the API change.

## Releases

Versions are lockstep with the SwiftTUI org (`swift-tui`, `swift-tui-web`,
and examples). The manifest pins the matching `swift-tui` tag with `exact:`.
The org coordination root controls the release sequence and pin checks.
