import Foundation
import Testing

@testable import SwiftTUICharts

@Suite struct ChartSourceDataTests {
  @Test("thresholds preserve authored values and separately describe displayed clamping")
  func thresholds() {
    let data = thresholdChartData(
      value: 25, total: 20,
      bands: [.init(upTo: 30, tone: .warning), .init(upTo: -4, tone: .critical)])
    #expect(data.map(\.value) == [25, 20, 100, 30, -4])
    #expect(data[2].unit == "%")
    #expect(data[3].detail == "Displayed upper boundary 20.0, Warning")
    #expect(data[4].detail == "Displayed upper boundary 0.0, Critical")
  }

  @Test("calendar data follows civil days across DST and includes missing daily aggregates")
  func calendarDays() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
    let first = try #require(calendar.date(from: .init(year: 2026, month: 3, day: 7)))
    let last = try #require(calendar.date(from: .init(year: 2026, month: 3, day: 9)))
    let days: [DateValue] = [
      .init(first, value: 3.25), .init(first.addingTimeInterval(3600), value: 4),
      .init(last, value: 19.75), .init(first.addingTimeInterval(-86400), value: 200),
    ]
    for start in [CalendarHeatmapWeekStart.sunday, .monday] {
      let bucket = bucketDays(days, range: first...last, calendar: calendar, weekStart: start)
      let data = calendarHeatmapData(
        bucket: bucket, range: first...last, calendar: calendar, weekStart: start)
      #expect(data.map(\.category) == ["2026-03-07", "2026-03-08", "2026-03-09"])
      #expect(data.map(\.value) == [7.25, nil, 19.75])
      #expect(data[1].detail == "No data; gregorian, America/Los_Angeles")
      #expect(Set(data.compactMap(\.id)).count == 3)
    }
  }

  @Test("line data keeps precision, source order, gaps, date timezone and fill relationships")
  func lineMeaning() throws {
    var dateFormat = Date.FormatStyle().year().month(.twoDigits).day(.twoDigits)
      .locale(Locale(identifier: "en_US_POSIX"))
    dateFormat.timeZone = try #require(TimeZone(secondsFromGMT: -8 * 3600))
    let axis = LineChartXAxis.dates(every: .day, format: dateFormat)
    let series = [
      LineChartSeries(
        "Traffic",
        points: [
          .init(x: 0, y: 1.23456789),
          .init(x: -86400, y: .nan), .init(x: 86400, y: 8),
        ], style: .area)
    ]
    let data = lineChartData(series, xAxis: axis, baseline: .zero)
    #expect(data[0].category == "12/31/2000")
    #expect(data[0].value == 1.23456789)
    #expect(
      data[0].detail
        == "X coordinate 0.0; area interpolation; fill baseline 0.0 (clipped to plotted range)")
    #expect(data[1].value?.isNaN == true)
    #expect(data[1].detail?.contains("gap in the plotted series") == true)
    #expect(data[2].category == "01/01/2001")
    #expect(
      lineChartData(series, xAxis: .hidden)[0].detail?.contains("fill baseline 1.23456789") == true)
  }
}
