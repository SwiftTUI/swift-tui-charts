import Foundation
import Testing

@testable import SwiftTUICharts

@Suite("LineChart axis config")
struct LineChartAxisConfigTests {
  @Test("X axis .values builds numeric Ticks/Format")
  func xAxisValuesBuildsNumeric() {
    let axis = LineChartXAxis.values(count: 6)
    #expect(axis.isHidden == false)
    if case .count(let n) = axis.ticks {
      #expect(n == 6)
    } else {
      Issue.record("expected .count tick strategy")
    }
    if case .number = axis.format {
    } else {
      Issue.record("expected .number format")
    }
  }

  @Test("X axis .dates builds DateAxisStride / Date.FormatStyle")
  func xAxisDatesBuildsDateStride() {
    let axis = LineChartXAxis.dates(every: .month)
    if case .dates(let stride) = axis.ticks {
      #expect(stride == .month)
    } else {
      Issue.record("expected .dates tick strategy")
    }
    if case .date = axis.format {
    } else {
      Issue.record("expected .date format")
    }
  }

  @Test("X axis .hidden flips isHidden")
  func xAxisHiddenFlipsFlag() {
    #expect(LineChartXAxis.hidden.isHidden == true)
  }

  @Test("Y axis .values defaults to compact-name notation")
  func yAxisValuesDefaultsToCompact() {
    let axis = LineChartYAxis.values()
    if case .count(let n) = axis.ticks {
      #expect(n == 5)
    } else {
      Issue.record("expected .count tick strategy")
    }
    #expect(axis.isHidden == false)
    // FloatingPointFormatStyle is not Equatable, so we can't directly
    // compare against `.number.notation(.compactName)`. Verifying the
    // format produces compact notation on a large number is the next
    // best assertion of the documented default.
    let formatted = axis.format.format(1_000_000)
    #expect(formatted.contains("M") || formatted.contains("K"))
  }

  @Test("Legend config presets")
  func legendPresets() {
    #expect(LineChartLegendConfig.bottom.position == .bottom)
    #expect(LineChartLegendConfig.top.position == .top)
    #expect(LineChartLegendConfig.hidden.position == .hidden)
  }
}

@Suite("LineChart Y axis ticks")
struct LineChartYAxisTickTests {
  @Test("yAxisTickLabels with .count(N) yields N evenly spaced labels")
  func yAxisCountEvenSpacing() {
    let labels = yAxisTickLabels(
      domain: 0...100,
      ticks: .count(5),
      format: .number,
      plotHeight: 10
    )
    #expect(labels.count == 5)
    // First label at the top row, last at the bottom row.
    #expect(labels.first?.row == 0)
    #expect(labels.last?.row == 9)
  }

  @Test("yAxisTickLabels with .automatic falls back to 5 ticks")
  func yAxisAutomatic() {
    let labels = yAxisTickLabels(
      domain: 0...10,
      ticks: .automatic,
      format: .number,
      plotHeight: 8
    )
    #expect(labels.count == 5)
  }

  @Test("yAxisTickLabels formats values with the supplied FormatStyle")
  func yAxisFormat() {
    let labels = yAxisTickLabels(
      domain: 0...1_000_000,
      ticks: .count(2),
      format: .number.notation(.compactName),
      plotHeight: 5
    )
    #expect(labels[0].text.contains("M") || labels[0].text.contains("K"))
  }
}

@Suite("LineChart X axis ticks")
struct LineChartXAxisTickTests {
  @Test("xAxisTickLabels with .count(N) yields N evenly spaced labels")
  func xCountEvenSpacing() {
    let labels = xAxisTickLabels(
      domain: 0...100,
      ticks: .count(3),
      format: .number(.number),
      plotWidth: 20
    )
    #expect(labels.count == 3)
    #expect(labels.first?.col == 0)
    #expect(labels.last?.col == 19)
  }

  @Test("xAxisTickLabels with .dates(every: .month) snaps to month starts")
  func xDateStrideSnapsToMonth() {
    let cal = Calendar(identifier: .gregorian)
    var calUTC = cal
    calUTC.timeZone = TimeZone(identifier: "UTC")!
    // Range: 2024-01-15 ... 2024-04-15.
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]
    formatter.timeZone = TimeZone(identifier: "UTC")
    let start = formatter.date(from: "2024-01-15")!
    let end = formatter.date(from: "2024-04-15")!
    let labels = xAxisTickLabels(
      domain: start.timeIntervalSinceReferenceDate...end.timeIntervalSinceReferenceDate,
      ticks: .dates(every: .month),
      format: .date(.dateTime.month(.abbreviated)),
      plotWidth: 30,
      calendar: calUTC
    )
    // Expect ticks at Feb, Mar, Apr starts (within the range).
    let texts = labels.map(\.text)
    #expect(texts.contains("Feb"))
    #expect(texts.contains("Mar"))
    #expect(texts.contains("Apr"))
  }

  @Test("date tick labels use calendar timezone, not system timezone")
  func dateTicksRespectCalendarTimezone() {
    // Build a UTC gregorian calendar and a range that lands a tick at
    // 2024-02-01 00:00:00 UTC. Without pinTimezone(_:to:), machines west
    // of UTC would render that boundary as "Jan" because the system
    // timezone shifts it back into January local time. Pinning the
    // calendar's UTC timezone onto Date.FormatStyle forces "Feb".
    var calUTC = Calendar(identifier: .gregorian)
    calUTC.timeZone = TimeZone(identifier: "UTC")!
    let feb1UTC = ISO8601DateFormatter().date(from: "2024-02-01T00:00:00Z")!
    let oneDayLater = feb1UTC.addingTimeInterval(86_400)
    let labels = xAxisTickLabels(
      domain: feb1UTC.timeIntervalSinceReferenceDate...oneDayLater.timeIntervalSinceReferenceDate,
      ticks: .dates(every: .month),
      format: .date(.dateTime.month(.abbreviated)),
      plotWidth: 10,
      calendar: calUTC
    )
    #expect(labels.map(\.text).contains("Feb"))
  }

  // Calendar ticks lie on stride boundaries inside the domain (STUI-1176). Columns
  // are round(days from start / domain days × 79) on an 80-column plot.
  @Test(
    "calendar ticks stay on stride boundaries inside the domain",
    arguments: [
      CalendarTickCase(
        "w2c01/w2c02 quarter from mid-February", from: (2024, 2, 15), to: (2024, 8, 1),
        stride: .quarter, texts: ["Apr", "Jul"], columns: [22, 64]),
      CalendarTickCase(
        "w2c03 quarter across a year boundary", from: (2023, 11, 10), to: (2024, 5, 1),
        stride: .quarter, texts: ["Jan", "Apr"], columns: [24, 65]),
      CalendarTickCase(
        "w2c04 quarter without an interior boundary", from: (2024, 2, 15), to: (2024, 3, 20),
        stride: .quarter, texts: [], columns: []),
      CalendarTickCase(
        "w2c05 quarter starting on a boundary", from: (2024, 4, 1), to: (2024, 12, 31),
        stride: .quarter, texts: ["Apr", "Jul", "Oct"], columns: [0, 26, 53]),
      CalendarTickCase(
        "w2c06 month without an interior boundary", from: (2024, 2, 3), to: (2024, 2, 20),
        stride: .month, texts: [], columns: []),
    ])
  func calendarTicksStayInsideDomain(_ tickCase: CalendarTickCase) throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try #require(TimeZone(identifier: "UTC"))
    calendar.locale = Locale(identifier: "en_US_POSIX")
    let start = try #require(calendar.date(from: tickCase.start))
    let end = try #require(calendar.date(from: tickCase.end))
    let labels = xAxisTickLabels(
      domain: start.timeIntervalSinceReferenceDate...end.timeIntervalSinceReferenceDate,
      ticks: .dates(every: tickCase.stride),
      format: .date(.dateTime.month(.abbreviated).locale(Locale(identifier: "en_US_POSIX"))),
      plotWidth: 80,
      calendar: calendar
    )
    #expect(labels.map(\.text) == tickCase.texts)
    #expect(labels.map(\.col) == tickCase.columns)
  }
}

struct CalendarTickCase: Sendable, CustomTestStringConvertible {
  let name: String
  let start: DateComponents
  let end: DateComponents
  let stride: DateAxisStride
  let texts: [String]
  let columns: [Int]

  init(
    _ name: String, from: (Int, Int, Int), to: (Int, Int, Int), stride: DateAxisStride,
    texts: [String], columns: [Int]
  ) {
    self.name = name
    self.start = DateComponents(year: from.0, month: from.1, day: from.2)
    self.end = DateComponents(year: to.0, month: to.1, day: to.2)
    self.stride = stride
    self.texts = texts
    self.columns = columns
  }

  var testDescription: String { name }
}

// One tick per useful cell (STUI-1175). Over 0...10 the X lower bound maps to
// column 0 and the Y upper bound to row 0, so a one-cell axis keeps exactly that
// tick. An axis with two or more cells keeps both endpoint ticks.
@Suite("LineChart tick resolution cap")
struct LineChartTickResolutionTests {
  static let xStrategies: [LineChartXAxis.Ticks] = [
    .automatic, .count(0), .count(1), .count(5), .count(Int.max),
    .every(stride: 3), .every(stride: 100), .every(stride: 1e-12), .every(stride: 0),
    .every(stride: -1), .every(stride: .nan), .every(stride: .infinity),
  ]
  static let yStrategies: [LineChartYAxis.Ticks] = [
    .automatic, .count(0), .count(1), .count(5), .count(Int.max),
    .every(stride: 3), .every(stride: 100), .every(stride: 1e-12), .every(stride: 0),
    .every(stride: -1), .every(stride: .nan), .every(stride: .infinity),
  ]
  static let strides: [Double] = [0.5, 1, 2.5, 3, 7, 100, 1e-12, 0, -1, .nan]

  static var number: FloatingPointFormatStyle<Double> {
    .number.locale(Locale(identifier: "en_US_POSIX"))
  }

  @Test("a one-cell X axis keeps only its lower-bound tick (w3c01, w3c03)", arguments: xStrategies)
  func oneCellXAxis(ticks: LineChartXAxis.Ticks) {
    let labels = xAxisTickLabels(
      domain: 0...10, ticks: ticks, format: .number(Self.number), plotWidth: 1)
    #expect(labels == [AxisTickLabel(col: 0, text: "0")])
  }

  @Test("a nonpositive X plot width caps like one cell (w3c04)", arguments: [0, -3])
  func nonpositiveXWidth(plotWidth: Int) {
    let labels = xAxisTickLabels(
      domain: 0...10, ticks: .count(5), format: .number(Self.number), plotWidth: plotWidth)
    #expect(labels == [AxisTickLabel(col: 0, text: "0")])
  }

  @Test("a one-cell Y axis keeps only its upper-bound tick (w3c02, w3c05)", arguments: yStrategies)
  func oneCellYAxis(ticks: LineChartYAxis.Ticks) {
    let labels = yAxisTickLabels(domain: 0...10, ticks: ticks, format: Self.number, plotHeight: 1)
    #expect(labels == [AxisTickLabel(row: 0, text: "10")])
  }

  @Test("a nonpositive Y plot height caps like one cell (w3c06)", arguments: [0, -3])
  func nonpositiveYHeight(plotHeight: Int) {
    let labels = yAxisTickLabels(
      domain: 0...10, ticks: .count(5), format: Self.number, plotHeight: plotHeight)
    #expect(labels == [AxisTickLabel(row: 0, text: "10")])
  }

  @Test("a two-cell X axis keeps both endpoint ticks (w3c11)", arguments: xStrategies)
  func twoCellXAxis(ticks: LineChartXAxis.Ticks) {
    let labels = xAxisTickLabels(
      domain: 0...10, ticks: ticks, format: .number(Self.number), plotWidth: 2)
    #expect(labels == [AxisTickLabel(col: 0, text: "0"), AxisTickLabel(col: 1, text: "10")])
  }

  @Test("a two-cell Y axis keeps both endpoint ticks (w3c12)", arguments: yStrategies)
  func twoCellYAxis(ticks: LineChartYAxis.Ticks) {
    let labels = yAxisTickLabels(domain: 0...10, ticks: ticks, format: Self.number, plotHeight: 2)
    #expect(labels == [AxisTickLabel(row: 0, text: "10"), AxisTickLabel(row: 1, text: "0")])
  }

  @Test(
    "counted ticks on wider axes stay evenly spaced in distinct cells (w3c13)", arguments: 2...16)
  func countedTicksOnWiderAxes(cells: Int) {
    for n in 0...20 {
      let x = xAxisTickLabels(
        domain: 0...10, ticks: .count(n), format: .number(Self.number), plotWidth: cells)
      let y = yAxisTickLabels(
        domain: 0...10, ticks: .count(n), format: Self.number, plotHeight: cells)
      #expect(x.count == min(max(2, n), cells), "x count(\(n))")
      #expect(y.count == min(max(2, n), cells), "y count(\(n))")
      expectEndpointSpread(x.map(\.col), cells: cells)
      expectEndpointSpread(y.map(\.row), cells: cells)
      #expect(x.first?.text == "0" && x.last?.text == "10")
      #expect(y.first?.text == "10" && y.last?.text == "0")
    }
  }

  @Test(
    "stride ticks on wider axes stay evenly spaced in distinct cells (w3c14)", arguments: 2...16)
  func strideTicksOnWiderAxes(cells: Int) {
    for stride in Self.strides {
      let x = xAxisTickLabels(
        domain: 0...10, ticks: .every(stride: stride), format: .number(Self.number),
        plotWidth: cells)
      let y = yAxisTickLabels(
        domain: 0...10, ticks: .every(stride: stride), format: Self.number, plotHeight: cells)
      #expect((2...cells).contains(x.count), "x every(\(stride))")
      #expect((2...cells).contains(y.count), "y every(\(stride))")
      expectEndpointSpread(x.map(\.col), cells: cells)
      expectEndpointSpread(y.map(\.row), cells: cells)
      #expect(x.first?.text == "0" && x.last?.text == "10")
      #expect(y.first?.text == "10" && y.last?.text == "0")
    }
  }

  @Test("a degenerate span keeps its single label (w3c15)", arguments: [1, 8])
  func degenerateSpan(cells: Int) {
    let x = xAxisTickLabels(
      domain: 7...7, ticks: .count(5), format: .number(Self.number), plotWidth: cells)
    let y = yAxisTickLabels(domain: 7...7, ticks: .count(5), format: Self.number, plotHeight: cells)
    #expect(x == [AxisTickLabel(col: 0, text: "7")])
    #expect(y == [AxisTickLabel(row: 0, text: "7")])
  }

  @Test("a one-cell calendar axis keeps its aligned tick (w3c16)")
  func oneCellCalendarAxis() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try #require(TimeZone(identifier: "UTC"))
    calendar.locale = Locale(identifier: "en_US_POSIX")
    let start = try #require(calendar.date(from: DateComponents(year: 2024, month: 1, day: 15)))
    let end = try #require(calendar.date(from: DateComponents(year: 2024, month: 3, day: 15)))
    let labels = xAxisTickLabels(
      domain: start.timeIntervalSinceReferenceDate...end.timeIntervalSinceReferenceDate,
      ticks: .dates(every: .month),
      format: .date(.dateTime.month(.abbreviated).locale(Locale(identifier: "en_US_POSIX"))),
      plotWidth: 1,
      calendar: calendar
    )
    #expect(labels == [AxisTickLabel(col: 0, text: "Feb")])
  }

  /// Ticks start at cell 0, end at the last cell and strictly increase, with every gap
  /// within one cell of the ideal even spacing.
  private func expectEndpointSpread(
    _ positions: [Int], cells: Int, sourceLocation: SourceLocation = #_sourceLocation
  ) {
    #expect(positions.first == 0, sourceLocation: sourceLocation)
    #expect(positions.last == cells - 1, sourceLocation: sourceLocation)
    guard positions.count > 1 else { return }
    let ideal = Double(cells - 1) / Double(positions.count - 1)
    let gaps = zip(positions, positions.dropFirst()).map { $1 - $0 }
    #expect(
      gaps.allSatisfy { $0 > 0 && abs(Double($0) - ideal) < 1 }, sourceLocation: sourceLocation)
  }
}

@Suite("LineChart modifiers")
@MainActor
struct LineChartModifierTests {
  @Test("chartXAxis stores the supplied config")
  func storesXAxisConfig() {
    let chart = LineChart(series: [], height: 8).chartXAxis(.hidden)
    #expect(chart.xAxis.isHidden == true)
  }

  @Test("chartLegend stores legend config")
  func storesLegendConfig() {
    let chart = LineChart(series: [], height: 8).chartLegend(.hidden)
    #expect(chart.legend.position == .hidden)
  }

  @Test("chartYAxis stores the supplied config")
  func storesYAxisConfig() {
    let chart = LineChart(series: [], height: 8).chartYAxis(.hidden)
    #expect(chart.yAxis.isHidden == true)
  }

  @Test("chartBaseline stores baseline")
  func storesBaseline() {
    let chart = LineChart(series: [], height: 8).chartBaseline(.zero)
    #expect(chart.baseline == .zero)
  }
}
