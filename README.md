# SwiftTUICharts

**Compact charts for terminal UIs — bar, column, line, and stacked-bar charts, meters, gauges, sparklines, heatmaps, and timelines, all ordinary SwiftTUI views.**

![Swift 6.3](https://img.shields.io/badge/Swift-6.3-F05138?logo=swift&logoColor=white)
![Platforms](https://img.shields.io/badge/platforms-macOS%2015%2B%20%C2%B7%20Linux%20%C2%B7%20WASI-1E90FF)
![Status](https://img.shields.io/badge/status-0.7.0%20pre--release-DAA520)
![License](https://img.shields.io/badge/license-MIT-3DA639)

`swift-tui-charts` is the chart library for
[SwiftTUI](https://swifttui.sh) — SwiftUI semantics, drawn in terminal cells.
Every chart is an ordinary SwiftTUI `View` composed from the public
`SwiftTUIViews` authoring surface. Put one in a `VStack` next to your text and
controls. Give it plain Swift values. It renders across every SwiftTUI host and
terminal capability profile.

**Relation to Swift Charts.** This library is *not* a port of Apple's
[Swift Charts](https://developer.apple.com/documentation/charts). Swift Charts
builds every chart from one composable `Chart` grammar — mark types
(`BarMark`, `LineMark`, …) plus data-driven modifiers. Terminal cells are too
coarse for that grammar to survive honestly, so SwiftTUICharts ships typed
chart *views* instead: `BarChart`, `LineChart`, `Meter`, `Sparkline`, and
friends, each a purpose-built view with its own initializer. If you know
Swift Charts, expect the same "declare data, get a chart" feel — but per
chart type, not through a shared mark grammar.

```swift
import SwiftTUI
import SwiftTUICharts

struct Dashboard: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 1) {
      Meter("Budget", value: 84, total: 100, tone: .warning)
      Sparkline("Traffic", values: [24, 36, 32, 54, 72, 66, 84], tone: .info)
      BarChart("Queues", entries: [
        .init("sync", value: 18, tone: .info),
        .init("api", value: 12, tone: .success),
        .init("jobs", value: 8, tone: .warning),
      ])
    }
  }
}
```

## Installation

Add both packages to your `Package.swift` — the framework and the charts —
Then add the `SwiftTUICharts` product from `swift-tui-charts`:

```swift
dependencies: [
  .package(url: "https://github.com/SwiftTUI/swift-tui.git", exact: "0.7.0"),
  .package(url: "https://github.com/SwiftTUI/swift-tui-charts.git", exact: "0.7.0"),
],
targets: [
  .executableTarget(
    name: "MyApp",
    dependencies: [
      .product(name: "SwiftTUI", package: "swift-tui"),
      .product(name: "SwiftTUICharts", package: "swift-tui-charts"),
    ]
  )
]
```

> **Migrating from the in-framework `SwiftTUICharts`:** the module used to ship as a
> product of the `swift-tui` package (releases before the repository split).
> It now lives here. Keep each `import SwiftTUICharts` statement unchanged.
> Add the `swift-tui-charts` package dependency. Change the product
> declaration's `package:` value from `"swift-tui"` to `"swift-tui-charts"`.

## Chart families

| View | What it shows |
| --- | --- |
| `Meter` | A single fractional value on a horizontal track |
| `ThresholdGauge` | A value against authored threshold bands |
| `BarChart` / `ColumnChart` | Labeled values as horizontal bars / vertical columns |
| `ComparisonChart` | Current values against baselines |
| `BulletChart` | A value against a target marker |
| `StackedBarChart` | Segmented totals in one track |
| `Sparkline` | A compact trend line in one row |
| `HeatStrip` | Relative intensity as a strip of heat cells |
| `CalendarHeatmap` | GitHub-style weekday × week activity grid |
| `LineChart` | Multi-series `.line`/`.area`/`.step` plots with date- or value-aware axes |
| `Timeline` | Ordered events with tone-accented connectors |
| `Legend` | Labels paired with semantic tones |

Every chart carries an accessibility summary (`VoiceOver` hears a meaningful
description even when the visual is glyph art), participates in terminal
capability degradation (`true-color` down to `preview-ascii`), and renders
identically across the terminal, web, SwiftUI, and Android hosts.

## Documentation & support

- API reference: <https://swifttui.sh/docs/charts/documentation/swifttuicharts/>
- [Building dashboards guide](https://swifttui.sh/docs/charts/documentation/swifttuicharts/building-dashboards)
- Framework API reference: <https://swifttui.sh/docs/documentation/>
- Website & showcase: <https://swifttui.sh>
- Issues: <https://github.com/SwiftTUI/swift-tui-charts/issues>

**Other hosts and siblings:** the framework lives in
[`swift-tui`](https://github.com/SwiftTUI/swift-tui); examples in
[`swift-tui-examples`](https://github.com/SwiftTUI/swift-tui-examples)
(`git-viz` drives every chart primitive); the SwiftUI, browser, and Android
hosts in
[`swift-tui-swiftui`](https://github.com/SwiftTUI/swift-tui-swiftui),
[`swift-tui-web`](https://github.com/SwiftTUI/swift-tui-web), and
[`swift-tui-android`](https://github.com/SwiftTUI/swift-tui-android).

## Development

```bash
swiftly run swift build        # build
swiftly run swift test         # full test suite (fixtures included)
```

See [AGENTS.md](AGENTS.md) for repository conventions and the repo gate, and
[docs/](docs/README.md) for architecture notes.

## License

MIT — see [LICENSE](LICENSE).
