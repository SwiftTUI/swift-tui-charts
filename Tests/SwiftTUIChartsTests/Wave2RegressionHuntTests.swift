import Foundation
import Testing

@testable import SwiftTUICharts

// Wave-2 regression hunt, part CA (STUI-1165): neighbours of the 0.19.3
// quarter-tick, two-sided area and connector repairs (STUI-1176, 1177, 1178,
// 1213). Cases w2ca009-w2ca015; the hypotheses precede these tests in the
// hunt's evidence directory. Grids use the 5×5 plot over X 0...4 and Y -2...2
// (X maps to its column, Y 2...-2 to rows 0...4); `·` marks an empty cell.
@Suite("Wave-2 hunt CA: chart repair neighbours")
struct Wave2RegressionHuntTests {
  // MARK: Glyphs beside coincident samples (STUI-1213, STUI-1178)

  @Test("w2ca009 a duplicate sample before an equal-column successor keeps the vertical glyph")
  func w2ca009DuplicateBeforeEqualColumnSuccessorKeepsVerticalGlyph() {
    let withoutDuplicate = huntLine([(0, 2), (2, 0), (2, -2)])
    #expect(withoutDuplicate == ["╭─╮··", "··│··", "··│··", "··│··", "··╰··"])
    let withDuplicate = huntLine([(0, 2), (2, 0), (2, 0), (2, -2)])
    w2HuntKnown(
      """
      NEW-3: a duplicate sample before an equal-column successor renders ─ instead \
      of │; \
      dataPointGlyph reads arrival and departure from the immediately adjacent samples, \
      so a coincident neighbour (duplicate or same-cell sample) hides the real connector \
      direction; contract: LineChartModels.swift:34-35, docs/ARCHITECTURE.md:73-74; \
      adjacent STUI-1213, STUI-1178
      """
    ) {
      #expect(withDuplicate == withoutDuplicate)
    }
  }

  @Test("w2ca010 a duplicated final sample keeps the port of its vertical arrival")
  func w2ca010DuplicatedFinalSampleKeepsItsArrivalPort() {
    let withoutDuplicate = huntLine([(0, 2), (2, 0)])
    #expect(withoutDuplicate == ["╭─╮··", "··│··", "··╰··", "·····", "·····"])
    let withDuplicate = huntLine([(0, 2), (2, 0), (2, 0)])
    w2HuntKnown(
      """
      NEW-3: a duplicated final sample after a vertical arrival renders ─ instead \
      of ╰; \
      dataPointGlyph reads arrival and departure from the immediately adjacent samples, \
      so a coincident neighbour (duplicate or same-cell sample) hides the real connector \
      direction; contract: LineChartModels.swift:34-35, docs/ARCHITECTURE.md:73-74; \
      adjacent STUI-1213, STUI-1178
      """
    ) {
      #expect(withDuplicate == withoutDuplicate)
    }
  }

  @Test("w2ca011 a sample quantized into its predecessor's cell keeps the corner")
  func w2ca011QuantizedNearDuplicateKeepsTheCorner() {
    let withoutNearDuplicate = huntLine([(0, 2), (2, 0), (4, 0)])
    #expect(withoutNearDuplicate == ["╭─╮··", "··│··", "··╰──", "·····", "·····"])
    // (2.2, 0.2) maps to column 2, row 2, the cell of (2, 0).
    let withNearDuplicate = huntLine([(0, 2), (2, 0), (2.2, 0.2), (4, 0)])
    w2HuntKnown(
      """
      NEW-3: a sample quantized into its predecessor's cell renders ─ instead of the \
      ╰ corner; \
      dataPointGlyph reads arrival and departure from the immediately adjacent samples, \
      so a coincident neighbour (duplicate or same-cell sample) hides the real connector \
      direction; contract: LineChartModels.swift:34-35, docs/ARCHITECTURE.md:73-74; \
      adjacent STUI-1213, STUI-1178
      """
    ) {
      #expect(withNearDuplicate == withoutNearDuplicate)
    }
  }

  @Test("w2ca012 a horizontal arrival from the right before an upward equal-column successor")
  func w2ca012RightArrivalBeforeUpwardEqualColumnSuccessor() {
    #expect(huntLine([(4, 0), (2, 0), (2, 2)]) == ["··╭··", "··│··", "··╰──", "·····", "·····"])
  }

  // MARK: Two-sided area composition (STUI-1177)

  @Test("w2ca013 area series on opposite sides of a zero baseline share its row")
  func w2ca013OppositeSideAreasShareTheBaselineRow() {
    let composed = composeSeriesGrids(
      series: [
        LineChartSeries("above", points: huntPoints([(0, 1), (4, 1)]), style: .area),
        LineChartSeries("below", points: huntPoints([(0, -1), (4, -1)]), style: .area),
      ],
      domain: huntDomain, plotWidth: 5, plotHeight: 5, baselineRow: 2)
    #expect(huntRows(composed.grid) == ["·····", "─────", "▒▒▒▒▒", "─────", "·····"])
    #expect(composed.seriesIndex[1].allSatisfy { $0 == 0 })
    #expect(composed.seriesIndex[2].allSatisfy { $0 == 1 })
    #expect(composed.seriesIndex[3].allSatisfy { $0 == 1 })
  }

  // MARK: Quarter ticks (STUI-1176)

  @Test("w2ca014 quarter ticks from a mid-month start in every month are the quarter starts inside")
  func w2ca014QuarterTicksFromEveryMidMonthStart() throws {
    let calendar = try huntCalendar()
    let names = ["Jan", "Apr", "Jul", "Oct"]
    for month in 1...12 {
      let start = try #require(
        calendar.date(from: DateComponents(year: 2024, month: month, day: 15)))
      let end = start.addingTimeInterval(200 * 86_400)
      // Handwritten oracle: the first day of months 1, 4, 7 and 10 after the start.
      var expectedTexts: [String] = []
      var expectedColumns: [Int] = []
      for offset in 1...12 {
        let monthIndex = month - 1 + offset
        let calendarMonth = monthIndex % 12 + 1
        guard (calendarMonth - 1) % 3 == 0 else { continue }
        let boundary = try #require(
          calendar.date(
            from: DateComponents(year: 2024 + monthIndex / 12, month: calendarMonth, day: 1)))
        guard boundary <= end else { break }
        expectedTexts.append(names[(calendarMonth - 1) / 3])
        let fraction = boundary.timeIntervalSince(start) / end.timeIntervalSince(start)
        expectedColumns.append(Int((fraction * 79).rounded(.toNearestOrAwayFromZero)))
      }
      let labels = huntQuarterLabels(from: start, to: end, calendar: calendar)
      #expect(labels.map(\.text) == expectedTexts, "start month \(month)")
      #expect(labels.map(\.col) == expectedColumns, "start month \(month)")
    }
  }

  @Test("w2ca015 quarter ticks at the domain's closed boundaries")
  func w2ca015QuarterTickBoundaryEdges() throws {
    let calendar = try huntCalendar()
    func day(_ month: Int, _ day: Int) throws -> Date {
      try #require(calendar.date(from: DateComponents(year: 2024, month: month, day: day)))
    }
    let justAfter = huntQuarterLabels(
      from: try day(4, 1).addingTimeInterval(0.5), to: try day(9, 30), calendar: calendar)
    #expect(justAfter.map(\.text) == ["Jul"])
    let endingOnBoundary = huntQuarterLabels(
      from: try day(2, 15), to: try day(10, 1), calendar: calendar)
    #expect(endingOnBoundary.map(\.text) == ["Apr", "Jul", "Oct"])
    #expect(endingOnBoundary.last?.col == 79)
    let startingOnBoundary = huntQuarterLabels(
      from: try day(4, 1), to: try day(6, 30), calendar: calendar)
    #expect(startingOnBoundary.map(\.text) == ["Apr"])
    #expect(startingOnBoundary.map(\.col) == [0])
  }
}

// MARK: Helpers

/// Preserves an unmarked reproduction while guarding only confirmed assertions.
private func w2HuntKnown(_ comment: Comment, _ body: () -> Void) {
  if ProcessInfo.processInfo.environment["SWIFTTUI_W2HUNT_UNMARKED"] == "1" {
    body()
  } else {
    withKnownIssue(comment) { body() }
  }
}

private let huntDomain = LineChartDomain(x: 0...4, y: -2...2)

private func huntPoints(_ points: [(Double, Double)]) -> [LineChartPoint] {
  points.map { LineChartPoint(x: $0.0, y: $0.1) }
}

private func huntRows(_ grid: [[LineRasterCell?]]) -> [String] {
  grid.map { String($0.map { $0?.glyph ?? "·" }) }
}

private func huntLine(_ points: [(Double, Double)]) -> [String] {
  huntRows(
    rasterizeLine(points: huntPoints(points), domain: huntDomain, plotWidth: 5, plotHeight: 5))
}

private func huntCalendar() throws -> Calendar {
  var calendar = Calendar(identifier: .gregorian)
  calendar.timeZone = try #require(TimeZone(identifier: "UTC"))
  calendar.locale = Locale(identifier: "en_US_POSIX")
  return calendar
}

private func huntQuarterLabels(from start: Date, to end: Date, calendar: Calendar)
  -> [AxisTickLabel]
{
  xAxisTickLabels(
    domain: start.timeIntervalSinceReferenceDate...end.timeIntervalSinceReferenceDate,
    ticks: .dates(every: .quarter),
    format: .date(.dateTime.month(.abbreviated).locale(Locale(identifier: "en_US_POSIX"))),
    plotWidth: 80,
    calendar: calendar
  )
}
