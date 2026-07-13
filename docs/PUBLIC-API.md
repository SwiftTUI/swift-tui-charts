# Public API policy

- The public surface is enumerated in `docs/.public-api-baseline.txt` and
  enforced by `Scripts/check_public_api_baseline.sh` in the native gate.
  Additions and removals must be deliberate, reviewed, and land with the
  regenerated baseline in the same commit.
- Chart types preserve source compatibility with their last in-framework
  release wherever possible; this is a pre-1.0 package, so breaking changes
  are allowed but must be visible in the baseline diff and release notes.
- Prefer typed `@ViewBuilder` closures and generic `Label`/`Summary` type
  parameters over `AnyView`. A stored `AnyView` requires a nearby
  `AnyView policy:` comment (test fixtures only).
- No public API may expose framework-internal resolution types. If a chart
  needs a capability that public composition cannot express, raise it as a
  `swift-tui` boundary question instead of adding a workaround here.
