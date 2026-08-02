# Public API policy

- The public surface is enumerated in `docs/.public-api-baseline.txt` and
  enforced by `Scripts/check_public_api_baseline.sh` in the native gate.
  Each addition or removal requires review. Include the regenerated baseline
  in the same commit.
- Chart types preserve source compatibility with their last in-framework
  release where possible. This package is before version 1.0, so it permits
  breaking changes. Each breaking change must appear in the baseline diff and
  release notes.
- Prefer typed `@ViewBuilder` closures and generic `Label`/`Summary` type
  parameters over `AnyView`. A stored `AnyView` requires a nearby
  `AnyView policy:` comment (test fixtures only).
- No public API can expose framework-internal resolution types. If public
  composition cannot express a chart, discuss the `swift-tui` boundary. Do
  not add a workaround here.
