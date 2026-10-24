import Foundation
import SwiftTUIRuntime
import Testing

@testable import SwiftTUICharts

@Suite("Campaign C1 exact source and metric contracts")
struct CampaignC1DataTests {
  @Test(arguments: Array(61...75))
  func source(id: Int) throws {
    switch id {
    case 61:
      let records = lineChartData([.init("A", points: [.init(x: 3, y: .nan)])], xAxis: .automatic)
      #expect(records.count == 1 && records[0].category == "3")
      #expect(records[0].value?.isNaN == true)
      #expect(records[0].detail?.contains("gap in the plotted series") == true)
    case 62:
      let records = lineChartData([.init("A", points: [.init(x: .nan, y: 7)])], xAxis: .automatic)
      #expect(records[0].category == "Missing X coordinate" && records[0].value == 7)
      #expect(records[0].detail?.contains("gap in the plotted series") == true)
    case 63:
      let series = (0..<2).map { LineChartSeries("", points: [.init(x: Double($0), y: 1)]) }
      #expect(lineChartData(series, xAxis: .automatic).map(\.series) == ["Series 1", "Series 2"])
    case 64:
      let first = lineChartData([.init("A", points: [.init(x: 3, y: 1)])], xAxis: .automatic)
      let changed = lineChartData([.init("A", points: [.init(x: 3, y: 99)])], xAxis: .automatic)
      #expect(first[0].id == changed[0].id && changed[0].value == 99)
    case 65:
      let records = lineChartData(
        [
          .init("é:3", points: [.init(x: 4, y: 1)]),
          .init("é", points: [.init(x: 3, y: 1)]),
        ], xAxis: .automatic)
      #expect(Set(records.compactMap(\.id)).count == 2)
    case 66:
      let records = lineChartData(
        [
          .init("area", points: [.init(x: 0, y: 4)], style: .area),
          .init("low", points: [.init(x: 1, y: -3)]),
        ], xAxis: .automatic)
      #expect(records[0].detail?.contains("fill baseline -3.0") == true)
    case 67:
      let records = lineChartData(
        [.init("area", points: [.init(x: 0, y: 4), .init(x: 1, y: 8)], style: .area)],
        xAxis: .automatic, baseline: .zero)
      #expect(
        records.allSatisfy {
          $0.detail?.contains("fill baseline 0.0 (clipped to plotted range)") == true
        })
    case 68:
      let records = comparisonChartData([.init("A", current: -2, baseline: 4, total: 10)])
      #expect(records.map(\.series) == ["Current", "Baseline", "Total"])
      #expect(records.map(\.value) == [-2, 4, 10])
    case 69:
      let records = meterChartData(value: 20, total: 10)
      #expect(records.map(\.value) == [20, 10, 100])
      #expect(records[2].unit == "%")
    case 70:
      let records = thresholdChartData(
        value: 2, total: 100, bands: [.init(upTo: 150, tone: .warning)])
      #expect(records.last?.value == 150)
      #expect(records.last?.detail == "Displayed upper boundary 100.0, Warning")
    case 71:
      let records = barChartData([.init("debt", value: -4, tone: .critical)])
      #expect(records[0].value == -4 && records[0].detail == "Critical")
    case 72:
      #expect(lineChartData([.init("empty", points: [], style: .area)], xAxis: .automatic).isEmpty)
    case 73:
      let records = lineChartData(
        [.init("A", points: [.init(x: 2, y: 1), .init(x: 2, y: 3), .init(x: 2, y: 2)])],
        xAxis: .automatic)
      #expect(records.map(\.value) == [1, 3, 2])
    case 74:
      let calendar = try c1Calendar()
      let start = try c1Date(calendar, 2024, 1, 1)
      let end = try c1Date(calendar, 2024, 1, 2)
      let bucket = bucketDays(
        [.init(start, value: 0)], range: start...end, calendar: calendar, weekStart: .monday)
      let records = calendarHeatmapData(
        bucket: bucket, range: start...end, calendar: calendar, weekStart: .monday)
      let changedBucket = bucketDays(
        [.init(start, value: 99)], range: start...end, calendar: calendar, weekStart: .monday)
      let changed = calendarHeatmapData(
        bucket: changedBucket, range: start...end, calendar: calendar, weekStart: .monday)
      #expect(records.map(\.id) == changed.map(\.id))
      #expect(changed.map(\.value) == [99, nil])
    case 75:
      let records = thresholdChartData(value: 0, total: 0, bands: [])
      #expect(records.count == 4 && records[3].value == 1)
      #expect(records[3].detail == "Displayed upper boundary 1.0, Informational")
    default: Issue.record("unassigned C1 source scenario")
    }
  }

  @Test(arguments: Array(76...90))
  func metrics(id: Int) {
    func widths(_ values: [Double], total: Double, width: Int) -> [Int] {
      stackedBarWidths(
        entries: values.enumerated().map { .init(String($0.offset), value: $0.element) },
        total: total, barWidth: width)
    }
    switch id {
    case 76: #expect(widths([1, 2, 3], total: 10, width: 30) == [3, 6, 9])
    case 77: #expect(widths([-1, -3], total: 4, width: 8) == [2, 6])
    case 78:
      let result = widths([1, 1, 1, 1, 1], total: 5, width: 3)
      #expect(result.reduce(0, +) == 3 && result.allSatisfy { (0...1).contains($0) })
    case 79:
      let result = widths([1, 0, 1], total: 3, width: 10)
      #expect(result[1] == 0 && result.reduce(0, +) == 7)
    case 80:
      let expected = widths([0.3, 0.7], total: 2, width: 17)
      for scale in [1e-100, 1e100] {
        #expect(widths([0.3 * scale, 0.7 * scale], total: 2 * scale, width: 17) == expected)
      }
    case 81: #expect(columnChartFilledHeight(value: 1e-100, maximumValue: 1, chartHeight: 10) == 1)
    case 82:
      #expect(
        columnChartFilledHeight(value: -3, maximumValue: 10, chartHeight: 8)
          == columnChartFilledHeight(value: 3, maximumValue: 10, chartHeight: 8))
    case 83: #expect(columnChartFilledHeight(value: 30, maximumValue: 10, chartHeight: 8) == 8)
    case 84:
      #expect(
        [0.25, 0.5, 0.75].map { heatStripGlyph(value: $0, maximumValue: 1) } == ["▒", "▓", "█"])
    case 85:
      #expect(heatStripGlyph(value: 0, maximumValue: 1) == " ")
      #expect(heatStripGlyph(value: .leastNonzeroMagnitude, maximumValue: 1) == "░")
    case 86:
      let result = thresholdBandsSorted(
        [
          .init(upTo: 200, tone: .critical),
          .init(upTo: -10, tone: .info), .init(upTo: 50, tone: .warning),
        ], total: 100)
      #expect(result.map(\.upperBound) == [0, 50, 100])
      #expect(result.map(\.tone) == [.info, .warning, .critical])
    case 87:
      #expect(
        thresholdBandTone(
          for: 50, total: 100,
          bands: [.init(upTo: 50, tone: .success), .init(upTo: 100, tone: .critical)]) == .success)
    case 88:
      #expect(comparisonEntryTone(.init("A", current: 10, baseline: 1, tone: .warning)) == .warning)
      #expect(comparisonEntryTone(.init("A", current: 1, baseline: 10, tone: .info)) == .info)
    case 89:
      #expect(metricValueString(9.96) == "10.0")
      #expect(metricValueString(-9.96) == "-10.0")
    case 90:
      let empty = metricTrackString(fraction: -1, barWidth: 1)
      let full = metricTrackString(fraction: 2, barWidth: 1)
      #expect(empty.filled == "" && empty.empty == "─")
      #expect(full.filled == "█" && full.empty == "")
    default: Issue.record("unassigned C1 metric scenario")
    }
  }
}
