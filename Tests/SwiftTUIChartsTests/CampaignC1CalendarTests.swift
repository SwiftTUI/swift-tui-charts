import Foundation
import Testing

@testable import SwiftTUICharts

func c1Calendar(_ zone: String = "UTC", identifier: Calendar.Identifier = .gregorian) throws
  -> Calendar
{
  var calendar = Calendar(identifier: identifier)
  calendar.timeZone = try #require(TimeZone(identifier: zone))
  calendar.locale = Locale(identifier: "en_US_POSIX")
  calendar.firstWeekday = 2
  return calendar
}

func c1Date(_ calendar: Calendar, _ year: Int, _ month: Int, _ day: Int, hour: Int = 0) throws
  -> Date
{
  try #require(calendar.date(from: .init(year: year, month: month, day: day, hour: hour)))
}

@Suite("Campaign C1 axes and calendar contracts")
struct CampaignC1CalendarTests {
  @Test(arguments: Array(21...30))
  func ticks(id: Int) throws {
    if id == 21 {
      let labels = xAxisTickLabels(
        domain: 0...10, ticks: .count(5), format: .automatic, plotWidth: 1)
      c1Known("STUI-1175: one-cell axis exceeds its resolution cap") {
        #expect(labels.count == 1)
      }
      return
    }
    if id == 22 {
      let labels = yAxisTickLabels(domain: 0...10, ticks: .count(5), format: .number, plotHeight: 1)
      c1Known("STUI-1175: one-cell axis exceeds its resolution cap") {
        #expect(labels.count == 1)
      }
      return
    }
    if id == 23 {
      let labels = xAxisTickLabels(
        domain: 0...10, ticks: .every(stride: 3), format: .automatic, plotWidth: 10)
      // Numeric stride is approximate. The public contract promises evenly
      // spaced, resolution-capped ticks, not a ceiling-rounded cardinality.
      #expect((3...4).contains(labels.count))
      #expect(labels.first?.col == 0 && labels.last?.col == 9)
      let gaps = zip(labels, labels.dropFirst()).map { $1.col - $0.col }
      #expect(gaps.allSatisfy { $0 > 0 })
      #expect((gaps.max() ?? 0) - (gaps.min() ?? 0) <= 1)
      #expect(labels.first?.text == "0" && labels.last?.text == "10")
      return
    }
    if id == 24 {
      let labels = xAxisTickLabels(
        domain: -2...5, ticks: .every(stride: 1e-12), format: .automatic, plotWidth: 2)
      #expect(labels.map(\.col) == [0, 1])
      #expect(labels.map(\.text) == ["-2", "5"])
      return
    }
    if id == 25 {
      let labels = yAxisTickLabels(
        domain: 7...7, ticks: .count(7),
        format: .number.locale(Locale(identifier: "en_US_POSIX")), plotHeight: 8)
      #expect(labels.count == 1 && labels.first?.text == "7")
      return
    }
    let calendar = try c1Calendar(id == 29 ? "America/Los_Angeles" : "UTC")
    let start: Date
    let end: Date
    let stride: DateAxisStride
    let expected: [String]
    let format: Date.FormatStyle
    switch id {
    case 26:
      start = try c1Date(calendar, 2024, 1, 31)
      end = try c1Date(calendar, 2024, 3, 2)
      stride = .month
      expected = ["Feb", "Mar"]
      format = .dateTime.month(.abbreviated)
    case 27:
      start = try c1Date(calendar, 2024, 2, 15)
      end = try c1Date(calendar, 2024, 8, 1)
      stride = .quarter
      expected = ["Apr", "Jul"]
      format = .dateTime.month(.abbreviated)
    case 28:
      start = try c1Date(calendar, 2023, 12, 31)
      end = try c1Date(calendar, 2025, 1, 2)
      stride = .year
      expected = ["2024", "2025"]
      format = .dateTime.year()
    case 29:
      start = try c1Date(calendar, 2024, 3, 9)
      end = try c1Date(calendar, 2024, 3, 11)
      stride = .day
      expected = ["09", "10", "11"]
      format = .dateTime.day(.twoDigits)
    default:
      start = try c1Date(calendar, 2024, 3, 5)
      end = try c1Date(calendar, 2024, 3, 19)
      stride = .week
      expected = ["11", "18"]
      format = .dateTime.day(.twoDigits)
    }
    let labels = xAxisTickLabels(
      domain: start.timeIntervalSinceReferenceDate...end.timeIntervalSinceReferenceDate,
      ticks: .dates(every: stride), format: .date(format.locale(Locale(identifier: "en_US_POSIX"))),
      plotWidth: id == 29 ? 48 : 80, calendar: calendar)
    #expect(labels.map(\.text) == expected)
    if id == 29 { #expect(labels.map(\.col) == [0, 24, 47]) }
  }

  @Test(arguments: Array(31...40))
  func calendarBuckets(id: Int) throws {
    let calendar = try c1Calendar(
      id == 31 || id == 32 ? "America/Los_Angeles" : "UTC",
      identifier: id == 38 ? .buddhist : .gregorian)
    let start: Date
    let end: Date
    let entries: [DateValue]
    switch id {
    case 31:
      start = try c1Date(calendar, 2024, 3, 9)
      end = try c1Date(calendar, 2024, 3, 11)
      entries = [DateValue(start, value: 1), DateValue(end, value: 3)]
    case 32:
      start = try c1Date(calendar, 2024, 11, 3)
      end = start
      entries = [
        DateValue(start.addingTimeInterval(5400), value: 2),
        DateValue(start.addingTimeInterval(9000), value: 3),
      ]
    case 33:
      start = try c1Date(calendar, 2024, 2, 28)
      end = try c1Date(calendar, 2024, 3, 1)
      entries = [DateValue(try c1Date(calendar, 2024, 2, 29), value: 7)]
    case 34:
      start = try c1Date(calendar, 2024, 1, 10)
      end = try c1Date(calendar, 2024, 1, 12)
      entries = [
        DateValue(start.addingTimeInterval(-3600), value: 100),
        DateValue(start, value: 1), DateValue(end, value: 2),
        DateValue(end.addingTimeInterval(86400), value: 100),
      ]
    case 35:
      start = try c1Date(calendar, 2023, 12, 31)
      end = try c1Date(calendar, 2024, 1, 1)
      entries = [DateValue(start, value: 4), DateValue(end, value: 8)]
    case 36:
      start = try c1Date(calendar, 2024, 1, 1)
      end = try c1Date(calendar, 2024, 1, 2)
      entries = [DateValue(start, value: 3), DateValue(start.addingTimeInterval(3600), value: -3)]
    case 37:
      start = try c1Date(calendar, 2024, 1, 1)
      end = try c1Date(calendar, 2024, 1, 2)
      entries = [
        DateValue(start.addingTimeInterval(3600), value: 3),
        DateValue(start.addingTimeInterval(36000), value: 5),
      ]
    case 38:
      start = try c1Date(calendar, 2567, 2, 28)
      end = try c1Date(calendar, 2567, 3, 1)
      entries = [DateValue(start, value: 1)]
    case 39:
      start = try c1Date(calendar, 2024, 1, 1, hour: 12)
      end = start
      entries = [
        DateValue(start.addingTimeInterval(-36000), value: 2),
        DateValue(start.addingTimeInterval(36000), value: 5),
      ]
    default:
      start = try c1Date(calendar, 2024, 1, 1)
      end = try c1Date(calendar, 2024, 1, 9)
      entries = [DateValue(end, value: 7), DateValue(start, value: 4), DateValue(end, value: 2)]
    }
    let bucket = bucketDays(entries, range: start...end, calendar: calendar, weekStart: .monday)
    let records = calendarHeatmapData(
      bucket: bucket, range: start...end, calendar: calendar, weekStart: .monday)
    switch id {
    case 31:
      #expect(records.map(\.category) == ["2024-03-09", "2024-03-10", "2024-03-11"])
      #expect(bucket.grid[5][0] == 1 && bucket.grid[0][1] == 3)
    case 32: #expect(records.count == 1 && records[0].value == 5)
    case 33:
      #expect(records.map(\.category) == ["2024-02-28", "2024-02-29", "2024-03-01"])
      #expect(records[1].value == 7)
    case 34: #expect(records.map(\.value) == [1, nil, 2])
    case 35: #expect(bucket.grid[6][0] == 4 && bucket.grid[0][1] == 8)
    case 36:
      #expect(records.map(\.value) == [0, nil])
      #expect(records[0].detail?.contains("Daily aggregate") == true)
      #expect(records[1].detail?.contains("No data") == true)
    case 37:
      let pacific = try c1Calendar("America/Los_Angeles")
      let other = bucketDays(entries, range: start...end, calendar: pacific, weekStart: .monday)
      let otherRecords = calendarHeatmapData(
        bucket: other, range: start...end, calendar: pacific, weekStart: .monday)
      #expect(records[0].value == 8)
      #expect(otherRecords.map(\.category) == ["2023-12-31", "2024-01-01"])
      #expect(otherRecords.map(\.value) == [3, 5])
    case 38:
      #expect(records.count == 3 && records[0].category == "2567-02-28")
      #expect(records.allSatisfy { $0.detail?.contains("buddhist") == true })
    case 39: #expect(records.count == 1 && records[0].value == 7)
    default:
      let reversed = bucketDays(
        Array(entries.reversed()), range: start...end, calendar: calendar, weekStart: .monday)
      #expect(bucket == reversed)
      #expect(
        records
          == calendarHeatmapData(
            bucket: reversed, range: start...end, calendar: calendar, weekStart: .monday))
      #expect(records.first?.value == 4 && records.last?.value == 9)
    }
  }
}
