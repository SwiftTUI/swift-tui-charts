// Chart-local metric formatting helpers.
//
// These intentionally mirror the private formatting behavior of the
// framework's built-in metric controls (`ProgressView`, `Gauge`) so chart
// summaries and tracks render identically alongside them, without the chart
// library reaching into package-only framework internals.

func progressFraction(
  value: Double,
  total: Double
) -> Double {
  guard value.isFinite, total.isFinite else { return 0 }
  guard total > 0 else {
    return value > 0 ? 1 : 0
  }

  if value <= 0 { return 0 }
  if value >= total { return 1 }
  return value / total
}

func metricValueString(
  _ value: Double
) -> String {
  if value.isNaN || value.isInfinite {
    return "0"
  }

  let rounded = value.rounded()
  if abs(rounded - value) < 0.000_1 {
    return Int(exactly: rounded).map(String.init) ?? String(value)
  }

  let scaled = (value * 10).rounded() / 10
  let sign = scaled < 0 ? "-" : ""
  let absolute = abs(scaled)
  guard let whole = Int(exactly: absolute.rounded(.towardZero)),
    let tenths = Int(exactly: (absolute * 10).rounded())
  else { return String(value) }
  let fractional = tenths % 10
  return "\(sign)\(whole).\(fractional)"
}

func progressSummaryText(
  value: Double,
  total: Double
) -> String {
  "\(metricValueString(value))/\(metricValueString(total))"
}

func meterSummaryText(
  value: Double,
  total: Double
) -> String {
  let percentage = Int((progressFraction(value: value, total: total) * 100).rounded())
  return "\(percentage)%"
}

func metricTrackString(
  fraction: Double,
  barWidth: Int
) -> (filled: String, empty: String) {
  let segmentCount = max(1, barWidth)
  let filledCount = chartCellOffset(fraction, maximum: segmentCount)
  let emptyCount = max(0, segmentCount - filledCount)
  return (
    filled: String(repeating: "█", count: filledCount),
    empty: String(repeating: "─", count: emptyCount)
  )
}
