import Foundation

struct AxisTickLabel: Equatable, Sendable {
  var row: Int
  var col: Int
  var text: String
}

extension AxisTickLabel {
  init(row: Int, text: String) { self.init(row: row, col: 0, text: text) }
  init(col: Int, text: String) { self.init(row: 0, col: col, text: text) }
}

/// Computes the X-axis tick labels for `LineChart`.
/// If `ticks` is `.dates(...)`, the function aligns ticks with calendar boundaries.
/// The function also applies the calendar time zone to the format style for deterministic output.
func xAxisTickLabels(
  domain: ClosedRange<Double>,
  ticks: LineChartXAxis.Ticks,
  format: LineChartXAxis.Format,
  plotWidth: Int,
  calendar: Calendar = defaultGregorianUTC
) -> [AxisTickLabel] {
  let width = max(1, plotWidth)
  let span = domain.upperBound - domain.lowerBound
  guard span > 0 else {
    return [AxisTickLabel(col: 0, text: formatX(value: domain.lowerBound, using: format))]
  }

  switch ticks {
  case .automatic:
    return evenlySpacedXTicks(count: 5, domain: domain, plotWidth: width, format: format)
  case .count(let n):
    return evenlySpacedXTicks(count: max(2, n), domain: domain, plotWidth: width, format: format)
  case .every(let stride):
    let count = boundedStrideTickCount(span: span, stride: stride, cells: width)
    return evenlySpacedXTicks(count: count, domain: domain, plotWidth: width, format: format)
  case .dates(let stride):
    return dateStrideXTicks(
      stride: stride,
      domain: domain,
      plotWidth: width,
      format: format,
      calendar: calendar
    )
  }
}

private let defaultGregorianUTC: Calendar = {
  var cal = Calendar(identifier: .gregorian)
  cal.timeZone = TimeZone(identifier: "UTC")!
  return cal
}()

private func evenlySpacedXTicks(
  count: Int,
  domain: ClosedRange<Double>,
  plotWidth: Int,
  format: LineChartXAxis.Format
) -> [AxisTickLabel] {
  let count = min(max(2, count), max(2, plotWidth))
  var out: [AxisTickLabel] = []
  for i in 0..<count {
    let fraction = Double(i) / Double(count - 1)
    let value = chartInterpolatedValue(fraction, in: domain)
    let col = chartCellOffset(fraction, maximum: plotWidth - 1)
    out.append(AxisTickLabel(col: col, text: formatX(value: value, using: format)))
  }
  return out
}

private func dateStrideXTicks(
  stride: DateAxisStride,
  domain: ClosedRange<Double>,
  plotWidth: Int,
  format: LineChartXAxis.Format,
  calendar: Calendar
) -> [AxisTickLabel] {
  let endDate = Date(timeIntervalSinceReferenceDate: domain.upperBound)

  let component: Calendar.Component
  switch stride {
  case .day: component = .day
  case .week: component = .weekOfYear
  case .month: component = .month
  case .quarter: component = .quarter
  case .year: component = .year
  }

  var out: [AxisTickLabel] = []
  let tzPinnedFormat = pinTimezone(calendar.timeZone, to: format)
  var previous: Date?
  // Sample the full domain at the available resolution, then align forward
  // to calendar boundaries. Dense strides are thinned without iterating every
  // underlying day/month or truncating coverage to the start of the chart.
  for column in 0..<max(1, plotWidth) {
    let fraction = Double(column) / Double(max(1, plotWidth - 1))
    let sample = Date(timeIntervalSinceReferenceDate: chartInterpolatedValue(fraction, in: domain))
    let current = nextStrideBoundary(after: sample, component: component, calendar: calendar)
    guard current <= endDate, current != previous else { continue }
    let value = current.timeIntervalSinceReferenceDate
    let col = xCell(value: value, domain: domain, plotWidth: plotWidth)
    out.append(AxisTickLabel(col: col, text: formatX(value: value, using: tzPinnedFormat)))
    previous = current
  }
  return out
}

private func pinTimezone(
  _ timeZone: TimeZone,
  to format: LineChartXAxis.Format
) -> LineChartXAxis.Format {
  switch format {
  case .date(var style):
    style.timeZone = timeZone
    return .date(style)
  default:
    return format
  }
}

private func nextStrideBoundary(
  after date: Date,
  component: Calendar.Component,
  calendar: Calendar
) -> Date {
  var truncated = date
  switch component {
  case .day:
    truncated = calendar.startOfDay(for: date)
  case .weekOfYear:
    truncated = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
  case .month:
    truncated = calendar.dateInterval(of: .month, for: date)?.start ?? date
  case .quarter:
    truncated = calendar.dateInterval(of: .quarter, for: date)?.start ?? date
  case .year:
    truncated = calendar.dateInterval(of: .year, for: date)?.start ?? date
  default:
    break
  }
  if truncated < date, let next = calendar.date(byAdding: component, value: 1, to: truncated) {
    return next
  }
  return truncated
}

private func formatX(value: Double, using format: LineChartXAxis.Format) -> String {
  switch format {
  case .automatic, .number:
    let style: FloatingPointFormatStyle<Double>
    if case .number(let s) = format { style = s } else { style = .number }
    return style.format(value)
  case .date(let style):
    return Date(timeIntervalSinceReferenceDate: value).formatted(style)
  }
}

func yAxisTickLabels(
  domain: ClosedRange<Double>,
  ticks: LineChartYAxis.Ticks,
  format: FloatingPointFormatStyle<Double>,
  plotHeight: Int
) -> [AxisTickLabel] {
  let height = max(1, plotHeight)
  let span = domain.upperBound - domain.lowerBound

  let count: Int
  switch ticks {
  case .automatic:
    count = min(5, max(2, height))
  case .count(let n):
    count = min(max(2, n), max(2, height))
  case .every(let stride):
    count = boundedStrideTickCount(span: span, stride: stride, cells: height)
  }

  guard span > 0 else {
    return [AxisTickLabel(row: 0, text: format.format(domain.lowerBound))]
  }

  var out: [AxisTickLabel] = []
  for i in 0..<count {
    let fraction = Double(i) / Double(count - 1)
    let value = chartInterpolatedValue(1 - fraction, in: domain)
    let row = chartCellOffset(fraction, maximum: height - 1)
    out.append(AxisTickLabel(row: row, text: format.format(value)))
  }
  return out
}

private func boundedStrideTickCount(span: Double, stride: Double, cells: Int) -> Int {
  let limit = max(2, cells)
  guard stride.isFinite, stride > 0 else { return min(5, limit) }
  let requested = span / stride
  guard requested.isFinite, requested < Double(limit) else { return limit }
  return max(2, Int(requested))
}
