# SwiftTUICharts

**Compact charts for SwiftTUI apps: bar, column, line, and stacked-bar charts, meters, gauges, sparklines, heatmaps, and timelines.**

![Swift 6.4](https://img.shields.io/badge/Swift-6.4-F05138?logo=swift&logoColor=white)
![Platforms](https://img.shields.io/badge/platforms-macOS%2015%2B%20%C2%B7%20Linux%20%C2%B7%20WASI-1E90FF)
![Status](https://img.shields.io/badge/status-0.22.0%20pre--release-DAA520)
![License](https://img.shields.io/badge/license-MIT-3DA639)

`swift-tui-charts` is a chart library for [SwiftTUI](https://swifttui.sh). Every chart is an ordinary SwiftTUI `View`.


This library is not a port of Apple's [Swift Charts](https://developer.apple.com/documentation/charts). Swift Charts
builds every chart from a composable `Chart` grammar: mark types like `BarMark`, and data-driven modifiers.  
Terminal cells are too coarse for that grammar to survive, so SwiftTUICharts ships typed
chart views instead.

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

Add the `SwiftTUICharts` product from `swift-tui-charts` to your `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/SwiftTUI/swift-tui.git", .upToNextMajor(from: "0.24.0")),
  .package(url: "https://github.com/SwiftTUI/swift-tui-charts.git", .upToNextMajor(from: "0.22.0")),
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

Charts carry an accessibility summary for `VoiceOver`, participate in terminal
capability degradation (`true-color` down to `preview-ascii`), and render
identically across the terminal, web, SwiftUI, and Android hosts.

## Documentation & support

- API reference: <https://swifttui.sh/docs/charts/documentation/swifttuicharts/>
- [Building dashboards guide](https://swifttui.sh/docs/charts/documentation/swifttuicharts/building-dashboards)


## Development

```bash
swiftly run swift build        # build
swiftly run swift test         # full test suite (fixtures included)
```

## License

[MIT](LICENSE).

## Version compatibility

See the [compatibility policy](docs/COMPATIBILITY.md) for supported major lines,
independent dependency adoption, and experimental interfaces.
