# AGENTS.md

Guidance for Claude Code and other agentic assistants working in this
repository. Keep this file concise. [README.md](README.md) is the public
introduction. [docs/](docs/README.md) holds internal notes.

## What this repo is

`swift-tui-charts` ships the `SwiftTUICharts` module: chart and metric views
for [SwiftTUI](https://github.com/SwiftTUI/swift-tui). Every chart is an
ordinary SwiftTUI `View` composed from the public `SwiftTUIViews` authoring
surface. This package uses **no** package-internal framework API. The
`swift-tui` dependency is a public, exact-tagged HTTPS dependency. Only the
SwiftTUI org coordination overlay can rewrite it to a local path.

## Build & Test Commands

```bash
swiftly run swift build                            # Build
swiftly run swift test                             # Full test suite
swiftly run swift test --filter LineChartRasterTests   # One suite
tools/bazel/native_gate.sh                         # Repo gate (tests + API baseline)
Scripts/check_public_api_baseline.sh               # Public API drift check
Scripts/generate_public_api_baseline.sh            # Regenerate after reviewed API changes
swift format format -i --recursive --configuration .swift-format.json Sources/ Tests/
```

Do not run builds or tests with bare `swift` — use `swiftly run swift ...` so
runs match the pinned toolchain in `.swift-version`.

## Structure

- `Sources/SwiftTUICharts/` — contains one file for each chart family,
  `*Support.swift` helpers, and `SwiftTUICharts.docc/`. Charts import only
  `SwiftTUIViews`. Date and calendar files also import `Foundation`.
- `Tests/SwiftTUIChartsTests/` — contains the Swift Testing suites. `Support/`
  contains the rendered-text fixture harness, which uses only public
  SwiftTUIRuntime API. `Fixtures/` contains checked-in fixtures for 15 chart
  cases and 5 terminal profiles. Treat fixture changes as evidence, not
  housekeeping.

## Rules

- For each public API change, regenerate `docs/.public-api-baseline.txt` with
  the generation script. Include the baseline diff in the same commit. The
  native gate fails on unreviewed drift.
- No `PrimitiveView`/`ResolvableView`/`ResolveContext` usage — those are
  framework-internal. If a chart cannot be expressed with public composition,
  discuss the framework boundary. Do not add a local workaround.
- Use the code style in `.swift-format.json`: 2-space indentation, 100
  columns, ordered imports, and `private` instead of `fileprivate`.
- Do not store `AnyView` without an `AnyView policy:` comment (policy in
  [docs/PUBLIC-API.md](docs/PUBLIC-API.md)).
- Use Swift 6.3 language mode, strict memory safety, and the same upcoming
  features as `swift-tui` (see `Package.swift`).
- Use Swift Testing (`import Testing`, `@Test`, `#expect`) for tests.

## Pre-commit Hooks (prek)

- **swift-format** — auto-formats staged `.swift` files.
- **structured-concurrency-escape-hatches** — blocks `@unchecked Sendable`
  and `nonisolated(unsafe)`.
- **main-thread-usage** — forbids bare `Thread.isMainThread`.
- **no-ai-coauthors** — rejects commit messages with AI attribution trailers.

## Conventions

- `AGENTS.md` is the real file. `CLAUDE.md` is a symlink to it.
- Docs in this repo describe the state of `HEAD` only. Planning and proposal
  documents live in the SwiftTUI org coordination root, not here.
