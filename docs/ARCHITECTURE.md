# Architecture

`swift-tui-charts` ships one Swift module, `SwiftTUICharts`, built entirely
on the public `SwiftTUIViews` authoring surface of
[`swift-tui`](https://github.com/SwiftTUI/swift-tui).

## The boundary

- Every chart is an ordinary `View` with a compositional `body`: `VStack`,
  `HStack`, `Text`, `ForEach`, `Spacer`, and public style/metadata modifiers.
- The package names **no** framework-internal API. There is no
  `PrimitiveView`/`ResolvableView` conformance, no `ResolveContext`, and no
  package-access lowering anywhere in this repository.
- The single manifest dependency is the `SwiftTUIViews` product, pinned
  `exact:` to a public `swift-tui` tag. The `SwiftTUIViews` product re-exports
  `SwiftTUICore`. `SwiftTUICore` re-exports `SwiftTUIGraph` and
  `SwiftTUIPrimitives`. Thus, `import SwiftTUIViews` also provides the value
  vocabulary (`Color`, `AnyShapeStyle`, `SemanticMetadata`, and geometry
  types).
- `Exports.swift` re-exports `SwiftTUIViews`, so a consumer's
  `import SwiftTUICharts` also provides the authoring surface. This behavior
  matches the former module in `swift-tui`.

## Source layout

One file per chart family (`BarChart.swift`, `LineChart.swift`, …) plus:

- `ChartModels.swift`: the shared entry/value model types.
- `ChartChromeSupport.swift`: `BannerTone` and tone→style mapping.
- `ChartCommonSupport.swift`: the shared header, accessibility metadata,
  and the timeline/legend row renderers.
- `ChartMetricFormatting.swift`: chart-local metric/track formatting that
  mirrors the framework's built-in metric controls for output parity.
- `*Support.swift`: per-family layout math, kept pure and unit-testable.
- `LineChart*.swift`: domain, axes, tick, rasterization, and composition
  support for the line-chart family.

## Accessibility

Every chart attaches `SemanticMetadata` with `accessibilityRole: .image`, a
synthesized (or caller-provided) label, and an `AccessibilityVisualContent`
kind. Titled convenience initializers create a summary. Thus, assistive output
always receives a meaningful description. Custom charts without a label
trigger the framework's missing-label diagnostic.

## Tests

- Pure math suites (`LineChartDomainTests`, `ChartCoordinateConversionTests`,
  …) exercise the support functions directly via `@testable import`.
- `ChartSurfaceRenderTests` pins the user-visible glyph contract through the
  public one-shot renderer.
- `ChartRenderedTextFixtureTests` compares 15 chart cases across 5 terminal
  capability profiles with checked-in rendered fixtures
  (`Tests/SwiftTUIChartsTests/Fixtures/`).
- `ChartAccessibilityTests` pins assistive output through
  `SwiftTUITestSupport`'s linear accessibility helper.
- The `FrameworkStress*` suites exercise retained-render churn. Each generation
  renders under a retained graph. The suites compare its raster and semantics
  with a fresh render.
