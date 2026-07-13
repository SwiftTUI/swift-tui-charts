# Architecture

`swift-tui-charts` ships one Swift module, `SwiftTUICharts`, built entirely
on the public `SwiftTUIViews` authoring surface of
[`swift-tui`](https://github.com/SwiftTUI/swift-tui).

## The boundary

- Every chart is an ordinary `View` with a compositional `body` — `VStack`,
  `HStack`, `Text`, `ForEach`, `Spacer`, and public style/metadata modifiers.
- The package names **no** framework-internal API. There is no
  `PrimitiveView`/`ResolvableView` conformance, no `ResolveContext`, and no
  package-access lowering anywhere in this repository.
- The single manifest dependency is the `SwiftTUIViews` product, pinned
  `exact:` to a public `swift-tui` tag. `import SwiftTUIViews` is
  self-sufficient: the product re-exports `SwiftTUICore`, which re-exports
  `SwiftTUIGraph` and `SwiftTUIPrimitives`, so the value vocabulary
  (`Color`, `AnyShapeStyle`, `SemanticMetadata`, geometry types) is visible.
- `Exports.swift` re-exports `SwiftTUIViews`, so a consumer's
  `import SwiftTUICharts` also sees the authoring surface — matching how the
  module behaved when it shipped inside `swift-tui`.

## Source layout

One file per chart family (`BarChart.swift`, `LineChart.swift`, …) plus:

- `ChartModels.swift` — the shared entry/value model types.
- `ChartChromeSupport.swift` — `BannerTone` and tone→style mapping.
- `ChartCommonSupport.swift` — the shared header, accessibility metadata,
  and the timeline/legend row renderers.
- `ChartMetricFormatting.swift` — chart-local metric/track formatting,
  mirroring the framework's built-in metric controls for output parity.
- `*Support.swift` — per-family layout math, kept pure and unit-testable.
- `LineChart*.swift` — domain, axes, tick, rasterization, and composition
  support for the line-chart family.

## Accessibility

Every chart attaches `SemanticMetadata` with `accessibilityRole: .image`, a
synthesized (or caller-provided) label, and an `AccessibilityVisualContent`
kind. Titled convenience initializers synthesize a summary so assistive
output always hears a meaningful description; label-less custom charts
trigger the framework's missing-label diagnostic.

## Tests

- Pure math suites (`LineChartDomainTests`, `ChartCoordinateConversionTests`,
  …) exercise the support functions directly via `@testable import`.
- `ChartSurfaceRenderTests` pins the user-visible glyph contract through the
  public one-shot renderer.
- `ChartRenderedTextFixtureTests` verifies 15 chart cases × 5 terminal
  capability profiles against checked-in rendered fixtures
  (`Tests/SwiftTUIChartsTests/Fixtures/`).
- `ChartAccessibilityTests` pins assistive output through
  `SwiftTUITestSupport`'s linear accessibility helper.
- The `FrameworkStress*` suites stress retained-render churn: every
  generation re-renders under a retained graph and asserts raster/semantic
  equality with a fresh render.
