# Getting Started with SwiftTUICharts

Install the package, put a first chart in a view, and migrate from the
in-framework module.

## Overview

Every chart is an ordinary SwiftTUI `View` composed from the public
`SwiftTUIViews` authoring surface. Put one in a `VStack` next to your text and
controls, give it plain Swift values, and it renders across every SwiftTUI
host and terminal capability profile.

## Install

Add both packages to your `Package.swift` — the framework and the charts —
then depend on the `SwiftTUICharts` product:

```swift
dependencies: [
  .package(url: "https://github.com/SwiftTUI/swift-tui.git", exact: "0.11.0"),
  .package(url: "https://github.com/SwiftTUI/swift-tui-charts.git", exact: "0.11.0"),
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

## A First Dashboard

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

For which chart fits which data shape, layout guidance, and the full family
tour, continue with <doc:Building-Dashboards>.

## Migrating From the In-Framework Module

The module used to ship as a product of the `swift-tui` package (releases
before the repository split). It now lives here. Keep each
`import SwiftTUICharts` statement unchanged, add the `swift-tui-charts`
package dependency, and change the product declaration's `package:` value
from `"swift-tui"` to `"swift-tui-charts"`.

## Relation to Swift Charts

This library is *not* a port of Apple's Swift Charts. Terminal cells are too
coarse for a shared mark grammar to survive honestly, so SwiftTUICharts ships
typed chart *views* — ``BarChart``, ``LineChart``, ``Meter``, ``Sparkline``,
and friends — each a purpose-built view with its own initializer. If you know
Swift Charts, expect the same "declare data, get a chart" feel, but per chart
type.
