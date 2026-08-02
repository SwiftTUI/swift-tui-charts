# Building Dashboards

## Overview

`SwiftTUICharts` provides charts for dense operational surfaces.

The views in this module work best when they are paired with:

- `GroupBox` and `Section` for framing
- `LabeledContent` for precise labels
- `ViewThatFits` or custom `Layout` for adapting between wide and narrow terminal widths

## Choosing A Chart

- If the user needs one current value, use `ProgressView` or ``Meter``.
- If tone changes matter at defined boundaries, use ``ThresholdGauge``.
- To compare multiple values directly, use ``BarChart`` or ``ColumnChart``.
- If a baseline or target is important, use ``ComparisonChart`` or
  ``BulletChart``.
- For compact trend summaries, use ``Sparkline`` or ``Timeline``.

## Layout Guidance

Terminal dashboards are narrow compared to pixel-based UIs. Prefer:

- short labels
- explicit widths when comparison matters
- summary text outside the chart when the chart body is already dense
- stacked layouts that degrade cleanly under reduced width

## Pointer Coordinates

Chart helper math follows the package-wide coordinate split. Plot bounds are
integer `CellRect` values from layout, and pointer or hover locations are
continuous cell-space `Point` values. Convert from the continuous point into a
domain value at the chart boundary. Keep the chart layout cell-denominated.
Then the same view works with cell-only pointer fallback.

## Calendars and time series

### Calendar heatmap

For daily activity over a long period, use `CalendarHeatmap`. For example, it
can show commits or requests per day. Pass a flat array of `DateValue`. The
chart groups the values into a weekday-by-week grid.

```swift
CalendarHeatmap(
  "Activity",
  days: dailyCounts,
  weekStart: .monday
)
```

### Multi-series line chart

For continuous numeric or time-series data, use `LineChart`. It can show one
or more series. A series can be `.line`, `.area`, or `.step`. The X-axis can
use numbers or dates through `.chartXAxis(.dates(...))`.

```swift
LineChart(
  "Tokens per Day",
  series: [
    .init("Opus 4.7", points: opus47, tone: .info),
    .init("Opus 4.6", points: opus46, tone: .success),
    .init("Haiku 4.5", points: haiku45, tone: .warning),
  ],
  height: 8
)
.chartXAxis(.dates(every: .week))
.chartYAxis(.values(count: 6, format: .number.notation(.compactName)))
.chartLegend(.bottom)
```
