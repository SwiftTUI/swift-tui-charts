import Foundation
import SwiftTUIViews

func chartDataTone(_ tone: BannerTone) -> String? {
  switch tone {
  case .info: "Informational"
  case .success: "Success"
  case .warning: "Warning"
  case .critical: "Critical"
  default: nil
  }
}

func barChartData(_ entries: [BarChartEntry]) -> [ChartDataRecord] {
  entries.map { .init($0.label, value: $0.value, detail: chartDataTone($0.tone)) }
}

func comparisonChartData(_ entries: [ComparisonEntry]) -> [ChartDataRecord] {
  entries.flatMap { entry in
    var records: [ChartDataRecord] = [
      .init(
        entry.label, value: entry.current, series: "Current", detail: chartDataTone(entry.tone)),
      .init(entry.label, value: entry.baseline, series: "Baseline"),
    ]
    if let total = entry.total { records.append(.init(entry.label, value: total, series: "Total")) }
    return records
  }
}

func meterChartData(value: Double, total: Double) -> [ChartDataRecord] {
  [
    .init("Value", value: value), .init("Total", value: total),
    .init(
      "Displayed fraction", value: progressFraction(value: value, total: total) * 100,
      detail: "Clamped to the displayed range", unit: "%"),
  ]
}

func thresholdChartData(value: Double, total: Double, bands: [ThresholdBand]) -> [ChartDataRecord] {
  let sourceBands = bands.isEmpty ? thresholdBandsSorted(bands, total: total) : bands
  return meterChartData(value: value, total: total)
    + sourceBands.enumerated().map { index, band in
      let displayed = thresholdBandsSorted([band], total: total)[0].upperBound
      return .init(
        "Band \(index + 1) upper boundary", value: band.upperBound,
        detail: ["Displayed upper boundary \(String(displayed))", chartDataTone(band.tone)]
          .compactMap { $0 }.joined(separator: ", "))
    }
}

func lineChartData(
  _ series: [LineChartSeries], xAxis: LineChartXAxis, baseline: LineChartBaseline = .auto
) -> [ChartDataRecord] {
  let domain = plotDomain(series: series)
  let fillBaseline = baseline == .zero ? 0 : domain?.y.lowerBound ?? 0
  return series.enumerated().flatMap { seriesIndex, series in
    series.points.map { point in
      let category: String
      if point.x.isFinite {
        category = formatX(value: point.x, using: xAxis.format)
      } else {
        category = "Missing X coordinate"
      }
      let seriesName = series.label.isEmpty ? "Series \(seriesIndex + 1)" : series.label
      var detail =
        "X coordinate \(String(point.x)); \(String(describing: series.style)) interpolation"
        + (!point.x.isFinite || !point.y.isFinite ? "; gap in the plotted series" : "")
      if series.style != .line {
        detail += "; fill baseline \(String(fillBaseline))"
        if let domain, !domain.y.contains(fillBaseline) { detail += " (clipped to plotted range)" }
      }
      if let tone = chartDataTone(series.tone) { detail += "; \(tone)" }
      return ChartDataRecord(
        category, value: point.y, series: seriesName, detail: detail,
        id: "\(seriesName.utf8.count):\(seriesName):\(String(point.x))")
    }
  }
}
