import Foundation
import Testing

@testable import SwiftTUICharts

struct ChartNumericBoundaryTests {
  @Test("nonfinite samples are gaps and never define a line domain")
  func missingSamples() {
    let missing = [LineChartPoint(x: .nan, y: 1), .init(x: 0, y: .infinity)]
    #expect(plotDomain(series: [.init("missing", points: missing)]) == nil)
    let points = [LineChartPoint(x: 0, y: 0), .init(x: 1, y: .nan), .init(x: 2, y: 1)]
    let domain = LineChartDomain(x: 0...2, y: 0...1)
    #expect(plotDomain(series: [.init("gaps", points: points)]) == domain)
    let line = rasterizeLine(points: points, domain: domain, plotWidth: 5, plotHeight: 3)
    #expect(line[2][0]?.glyph == "•")
    #expect(line[0][4]?.glyph == "•")
    #expect(line.allSatisfy { $0[2] == nil })
    let step = rasterizeStep(points: points, domain: domain, plotWidth: 5, plotHeight: 3)
    #expect(step.allSatisfy { $0[2] == nil })
  }

  @Test("extreme finite domains retain endpoints and midpoint without overflow")
  func extremeDomain() {
    let maximum = Double.greatestFiniteMagnitude
    let domain = -maximum...maximum
    #expect(xCell(value: -maximum, domain: domain, plotWidth: 81) == 0)
    #expect(xCell(value: 0, domain: domain, plotWidth: 81) == 40)
    #expect(xCell(value: maximum, domain: domain, plotWidth: 81) == 80)
    #expect(yCell(value: 0, domain: domain, plotHeight: 41) == 20)
    #expect(chartInterpolatedValue(0.5, in: domain) == 0)
    #expect(chartInterpolatedValue(0, in: domain) == -maximum)
    #expect(chartInterpolatedValue(1, in: domain) == maximum)
    #expect(xCell(value: .infinity, domain: 0...1, plotWidth: 80) == 0)
    #expect(chartCellOffset(1, maximum: Int.max) == Int.max)
  }

  @Test("step rasters accept descending and duplicate x in authored order")
  func descendingStep() {
    let grid = rasterizeStep(
      points: [.init(x: 2, y: 2), .init(x: 0, y: 0), .init(x: 0, y: 1)],
      domain: .init(x: 0...2, y: 0...2), plotWidth: 5, plotHeight: 3
    )
    #expect(grid[0][4]?.glyph == "─")
    #expect(grid[0][0]?.glyph == "│")
    #expect(grid[2][0]?.glyph == "│")
  }

  @Test("metric numeric boundaries are finite and formatting never converts an oversized Int")
  func metrics() {
    #expect(metricValueString(1e20) == "1e+20")
    #expect(!metricValueString(Double.greatestFiniteMagnitude).isEmpty)
    #expect(meterSummaryText(value: .nan, total: 1) == "0%")
    #expect(progressFraction(value: .infinity, total: 1) == 0)
    #expect(progressFraction(value: 1, total: .leastNonzeroMagnitude) == 1)
    #expect(columnChartFilledHeight(value: .nan, maximumValue: 1, chartHeight: 8) == 0)
    #expect(
      sparklineGlyphString([-.greatestFiniteMagnitude, .nan, .greatestFiniteMagnitude]) == "▁ █")
    #expect(
      stackedBarWidths(
        entries: [
          .init("a", value: .greatestFiniteMagnitude), .init("b", value: .greatestFiniteMagnitude),
          .init("missing", value: .nan),
        ],
        total: .infinity, barWidth: 10
      ) == [5, 5, 0])
  }

  @Test("tick counts are bounded by the plot even for zero or tiny strides")
  func boundedTicks() {
    for stride in [0, -1, Double.nan, .infinity, .leastNonzeroMagnitude] {
      let ticks = yAxisTickLabels(
        domain: 0...1, ticks: .every(stride: stride), format: .number, plotHeight: 8)
      #expect((2...8).contains(ticks.count))
    }
    let ticks = xAxisTickLabels(
      domain: -Double.greatestFiniteMagnitude...Double.greatestFiniteMagnitude,
      ticks: .count(Int.max), format: .automatic, plotWidth: 9
    )
    #expect(ticks.count == 9)
    #expect(ticks[4].text == "0")
  }

  @Test("empty and missing stack segments never receive remainder cells")
  func stackRemainders() {
    for missing in [Double.zero, .nan, .infinity] {
      #expect(
        stackedBarWidths(
          entries: [.init("a", value: 1), .init("missing", value: missing)],
          total: 10, barWidth: 10
        ) == [1, 0])
    }
  }

  @Test("dense calendar strides cover the full domain at bounded cost")
  func calendarCoverage() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try #require(TimeZone(identifier: "UTC"))
    let start = try #require(calendar.date(from: DateComponents(year: 2025, month: 1, day: 1)))
    let end = try #require(calendar.date(byAdding: .day, value: 365, to: start))
    let ticks = xAxisTickLabels(
      domain: start.timeIntervalSinceReferenceDate...end.timeIntervalSinceReferenceDate,
      ticks: .dates(every: .day), format: .automatic, plotWidth: 80, calendar: calendar
    )
    #expect(ticks.count <= 80)
    #expect(ticks.first?.col == 0)
    #expect(ticks.last?.col == 79)
    #expect(ticks.contains { (38...41).contains($0.col) })
    #expect(Set(ticks.map(\.col)).count > 70)
  }
}
