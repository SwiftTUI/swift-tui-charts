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

Line-chart plots use one public rich `Text` value per row. Adjacent cells with
the same semantic foreground style form a text run; axes and legends retain
their ordinary view composition. Plot cells therefore do not each require a
view identity. `DenseDashboardQualificationTests` preserves the preceding
cell-view output across all five terminal profiles at 80×24 and 160×60, with
1/8/32 series, and checks the accessible summary and a bounded graph size.

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

## Numeric input boundaries

Line and sparkline samples with NaN or infinite coordinates are gaps. Only
finite samples determine their domain; line connectors do not cross missing
samples. Line and step samples retain authored order, including descending
and duplicate X values. Finite domain interpolation remains valid even when
the difference between its endpoints would overflow `Double`.

Progress-style charts treat nonfinite values or totals as zero contribution.
Large finite metric labels use scientific notation when an integer conversion
would overflow. Stacked widths normalize finite weights before summing them;
zero and missing segments receive no cells. An explicit total larger than
the observed sum retains unfilled track capacity after rounding.

Axis tick generation is bounded by plot resolution (with a minimum of two
numeric endpoint ticks). Zero, negative, and nonfinite numeric strides use the
automatic count. Calendar ticks remain aligned to the requested boundary and
are thinned across the full domain at the available horizontal resolution.
