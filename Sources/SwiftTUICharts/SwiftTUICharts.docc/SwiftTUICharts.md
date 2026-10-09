# ``SwiftTUICharts``

Compact charts and metric-oriented views composed from the public
`SwiftTUIViews` authoring surface.

## Overview

`SwiftTUICharts` is a separate product for operational surfaces, dashboards,
and compact summaries.

It includes:

- progress and gauge views
- bar, column, comparison, bullet, and stacked-bar charts
- sparklines and timelines
- legends and support models

The package composes on the public `SwiftTUIViews` authoring surface, so it
versions and upgrades independently of your app's runtime integration.

## Topics

### Guides

- <doc:Getting-Started>
- <doc:Building-Dashboards>

### Metric Views

- ``Meter``
- ``ThresholdGauge``

### Charts

- ``BarChart``
- ``ColumnChart``
- ``ComparisonChart``
- ``BulletChart``
- ``StackedBarChart``
- ``Sparkline``
- ``Timeline``
- ``HeatStrip``
- ``CalendarHeatmap``
- ``LineChart``

### Support Types

- ``BarChartEntry``
- ``ComparisonEntry``
- ``TimelineEntry``
- ``Legend``
- ``LegendItem``
- ``BannerTone``
- ``ThresholdBand``
- ``DateValue``
- ``LineChartPoint``
- ``LineChartSeries``
- ``LineChartSeriesStyle``
- ``LineChartXAxis``
- ``LineChartYAxis``
- ``LineChartLegendConfig``
- ``LineChartBaseline``
- ``DateAxisStride``
- ``CalendarHeatmapWeekStart``

### Guide

- <doc:Building-Dashboards>

## Accessible source data

All chart families publish bounded data review alongside their authored headers.
Use ``ChartDataView`` for custom graphics and `chartDataUnit(_:)` to supply units.
Data position, search and a remembered point support exact lookup and comparison
without adding painted rows. Application interactions need controls bound to the
same state as the visual chart.

- ``ChartDataView``
- ``ChartDataRecord``
