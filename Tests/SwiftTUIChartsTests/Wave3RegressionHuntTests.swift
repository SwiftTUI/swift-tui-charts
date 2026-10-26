import Foundation
import SwiftTUIRuntime
import Testing

@testable import SwiftTUICharts

// Wave-3 regression hunt, part CA (STUI-1167): neighbours of the 0.19.4 chart
// repairs, the one-tick-per-cell cap (STUI-1175, d49b12a) and the collapse of
// consecutive same-cell samples (STUI-1255, e621316). Cases w3ca013-w3ca019; the
// hypotheses precede these tests in the hunt's evidence directory.
@MainActor
@Suite("Wave-3 hunt CA: chart repair neighbours")
struct Wave3RegressionHuntChartTests {
  // MARK: Coincident samples through the public chart (STUI-1255)

  @Test("w3ca013 a public line chart draws exact duplicates as one sample")
  func w3ca013PublicLineChartDrawsExactDuplicatesAsOneSample() {
    let reduced = w3Surface(.line, [(0, 0), (2, 4), (4, 1), (6, 3)], "w3ca013-reduced")
    let duplicated = w3Surface(
      .line, [(0, 0), (0, 0), (2, 4), (2, 4), (4, 1), (6, 3), (6, 3)], "w3ca013-duplicated")
    #expect(reduced.contains { $0.contains("╮") || $0.contains("╯") })
    #expect(duplicated == reduced, "\(duplicated) versus \(reduced)")
  }

  @Test("w3ca014 public step and area charts draw exact duplicates as one sample")
  func w3ca014PublicStepAndAreaChartsDrawExactDuplicatesAsOneSample() {
    let reducedPoints: [(Double, Double)] = [(0, 1), (2, 3), (3, .nan), (4, 0), (6, 2)]
    let duplicatedPoints: [(Double, Double)] = [
      (0, 1), (0, 1), (2, 3), (3, .nan), (4, 0), (4, 0), (6, 2), (6, 2),
    ]
    for style in [LineChartSeriesStyle.step, .area] {
      let reduced = w3Surface(style, reducedPoints, "w3ca014-reduced-\(style)")
      let duplicated = w3Surface(style, duplicatedPoints, "w3ca014-duplicated-\(style)")
      #expect(duplicated == reduced, "\(style): \(duplicated) versus \(reduced)")
    }
  }

  @Test("w3ca015 a near-duplicate that extends the domain draws the reduced series' raster")
  func w3ca015NearDuplicateThatExtendsTheDomainKeepsTheReducedRaster() throws {
    let near: [(Double, Double)] = [(0, 0), (2, 2), (4, 4), (4.04, 4.04)]
    let reduced: [(Double, Double)] = [(0, 0), (2, 2), (4, 4)]
    // LineChart(width: 24, height: 5) plots 16 x 5 cells (LineChartSupport.swift:15-18).
    let nearSeries = [LineChartSeries("s", points: w3Points(near))]
    let nearDomain = try #require(plotDomain(series: nearSeries))
    // Precondition: in its own chart the near-duplicate shares its predecessor's cell.
    #expect(xCell(value: 4, domain: nearDomain.x, plotWidth: 16) == 15)
    #expect(xCell(value: 4.04, domain: nearDomain.x, plotWidth: 16) == 15)
    #expect(yCell(value: 4, domain: nearDomain.y, plotHeight: 5) == 0)
    #expect(yCell(value: 4.04, domain: nearDomain.y, plotHeight: 5) == 0)
    let withNear = try w3PublicGrid(near)
    let without = try w3PublicGrid(reduced)
    w3HuntKnown(
      "NEW-3: dropping a near-duplicate that is the domain's extreme rescales the public raster ((2,2) at column 7 versus 8); the domain spans every finite sample; contract: docs/ARCHITECTURE.md:74-77; adjacent STUI-1255"
    ) {
      #expect(withNear == without, "\(w3Rows(withNear)) versus \(w3Rows(without))")
    }
  }

  @Test("w3ca016 inserted exact duplicates never change the line, area or step raster")
  func w3ca016InsertedExactDuplicatesNeverChangeTheRaster() {
    var random = W3SplitMix64(seed: 0x3CA016)
    let domain = LineChartDomain(x: 0...10, y: 0...10)
    var failures: [String] = []
    for iteration in 0..<w3Iterations {
      let width = random.int(1...12)
      let height = random.int(1...8)
      var points: [LineChartPoint] = []
      for _ in 0..<random.int(1...10) {
        let x = random.unit() * 10
        points.append(.init(x: x, y: random.int(0...99) < 15 ? .nan : random.unit() * 10))
      }
      let finite = points.indices.filter { points[$0].y.isFinite }
      guard !finite.isEmpty else { continue }
      var duplicated = points
      for _ in 0..<random.int(1...4) {
        let candidates = duplicated.indices.filter { duplicated[$0].y.isFinite }
        let index = candidates[random.int(0...(candidates.count - 1))]
        duplicated.insert(duplicated[index], at: index + 1)
      }
      let baseline = random.int(0...(height - 1))
      func line(_ p: [LineChartPoint]) -> [[LineRasterCell?]] {
        rasterizeLine(points: p, domain: domain, plotWidth: width, plotHeight: height)
      }
      func step(_ p: [LineChartPoint]) -> [[LineRasterCell?]] {
        rasterizeStep(points: p, domain: domain, plotWidth: width, plotHeight: height)
      }
      func area(_ p: [LineChartPoint]) -> [[LineRasterCell?]] {
        rasterizeArea(
          points: p, domain: domain, plotWidth: width, plotHeight: height, baselineRow: baseline)
      }
      if line(duplicated) != line(points) || step(duplicated) != step(points)
        || area(duplicated) != area(points)
      {
        failures.append("iteration \(iteration) \(width)x\(height): \(points) -> \(duplicated)")
      }
    }
    #expect(failures.isEmpty, "\(failures.count) failures, first: \(failures.prefix(3))")
  }

  @Test("w3ca019 composition keeps the reduced grid and ownership over collapsed runs")
  func w3ca019CompositionKeepsOwnershipOverCollapsedRuns() {
    let domain = LineChartDomain(x: 0...4, y: 0...4)
    let line = LineChartSeries("a", points: w3Points([(0, 0), (4, 4)]))
    let duplicated = w3Points([(0, 4), (0, 4), (2, 2), (2, 2), (4, 0)])
    let reduced = w3Points([(0, 4), (2, 2), (4, 0)])
    for style in [LineChartSeriesStyle.step, .area] {
      func composed(_ points: [LineChartPoint]) -> ComposedSeriesGrid {
        composeSeriesGrids(
          series: [line, LineChartSeries("b", points: points, style: style)], domain: domain,
          plotWidth: 5, plotHeight: 5, baselineRow: 4)
      }
      let reducedGrid = composed(reduced)
      #expect(reducedGrid.seriesIndex.joined().contains(1), "\(style)")
      #expect(composed(duplicated) == reducedGrid, "\(style)")
    }
  }

  // MARK: One tick per useful cell (STUI-1175)

  @Test("w3ca017 tick counts stay within one per cell and keep their endpoints across domains")
  func w3ca017TickCountsStayWithinOnePerCellAcrossDomains() {
    var random = W3SplitMix64(seed: 0x3CA017)
    let style = FloatingPointFormatStyle<Double>.number.locale(Locale(identifier: "en_US_POSIX"))
    var failures: [String] = []
    for iteration in 0..<w3Iterations {
      let domain: ClosedRange<Double>
      switch random.int(0...9) {
      case 0: domain = -Double.greatestFiniteMagnitude...Double.greatestFiniteMagnitude
      case 1:
        let value = (random.unit() * 2 - 1) * 1e6
        domain = value...value
      default:
        let lower = (random.unit() * 2 - 1) * 1e6
        domain = lower...(lower + pow(10, random.unit() * 21 - 9))
      }
      let span = domain.upperBound - domain.lowerBound
      let strides: [Double] = [
        0, -1, .nan, .infinity, 1e-300, 1e300, span / Double(random.int(1...50)),
        random.unit() * span,
      ]
      let stride = strides[random.int(0...(strides.count - 1))]
      let count = random.int(-3...60)
      let cells = random.int(1...40)
      let xTicks: [LineChartXAxis.Ticks] = [.automatic, .count(count), .every(stride: stride)]
      let yTicks: [LineChartYAxis.Ticks] = [.automatic, .count(count), .every(stride: stride)]
      for (index, ticks) in xTicks.enumerated() {
        let labels = xAxisTickLabels(
          domain: domain, ticks: ticks, format: .number(style), plotWidth: cells)
        if let problem = w3TickProblem(
          labels.map { ($0.col, $0.text) }, cells: cells, span: span,
          first: style.format(domain.lowerBound), last: style.format(domain.upperBound))
        {
          failures.append("iteration \(iteration) X \(index) \(domain) cells \(cells): \(problem)")
        }
        let yLabels = yAxisTickLabels(
          domain: domain, ticks: yTicks[index], format: style, plotHeight: cells)
        if let problem = w3TickProblem(
          yLabels.map { ($0.row, $0.text) }, cells: cells, span: span,
          first: style.format(span > 0 ? domain.upperBound : domain.lowerBound),
          last: style.format(domain.lowerBound))
        {
          failures.append("iteration \(iteration) Y \(index) \(domain) cells \(cells): \(problem)")
        }
      }
    }
    #expect(failures.isEmpty, "\(failures.count) failures, first: \(failures.prefix(3))")
  }

  @Test("w3ca018 two- and three-row line charts label both Y endpoints")
  func w3ca018TwoAndThreeRowChartsLabelBothYEndpoints() {
    let expected: [Int: [String]] = [
      2: ["    10┤", "     0┼"],
      3: ["    10┤", "     5┤", "     0┼"],
    ]
    for (height, prefixes) in expected.sorted(by: { $0.key < $1.key }) {
      let points: [LineChartPoint] = [.init(x: 0, y: 0), .init(x: 10, y: 10)]
      let lines = DefaultRenderer().render(
        LineChart("Trend", series: [.init("trend", points: points)], height: height, width: 20)
          .chartYAxis(.values(count: 5, format: .number.locale(Locale(identifier: "en_US_POSIX"))))
          .chartXAxis(.hidden)
          .chartLegend(.hidden),
        context: .init(identity: testIdentity("W3HuntRows\(height)")),
        proposal: .init(width: 20, height: 8)
      ).rasterSurface.lines
      let indices = prefixes.map { prefix in lines.firstIndex { $0.hasPrefix(prefix) } }
      #expect(indices.allSatisfy { $0 != nil }, "height \(height): \(lines)")
      let found = indices.compactMap { $0 }
      #expect(found == found.sorted() && Set(found).count == found.count, "height \(height)")
    }
  }
}

// MARK: Helpers

/// Preserve an unmarked reproduction while guarding only confirmed assertions.
private func w3HuntKnown(_ comment: Comment, _ body: () -> Void) {
  if ProcessInfo.processInfo.environment["SWIFTTUI_W3HUNT_UNMARKED"] == "1" {
    body()
  } else {
    withKnownIssue(comment) { body() }
  }
}

private let w3Iterations =
  ProcessInfo.processInfo.environment["SWIFTTUI_STRESS_FULL"] == "1" ? 1_000 : 100

private func w3Points(_ points: [(Double, Double)]) -> [LineChartPoint] {
  points.map { LineChartPoint(x: $0.0, y: $0.1) }
}

private func w3Rows(_ grid: ComposedSeriesGrid) -> [String] {
  grid.grid.map { String($0.map { $0?.glyph ?? "·" }) }
}

/// The composed grid of a public chart's plot: the domain spans every finite sample.
private func w3PublicGrid(_ points: [(Double, Double)]) throws -> ComposedSeriesGrid {
  let series = [LineChartSeries("s", points: w3Points(points))]
  let domain = try #require(plotDomain(series: series))
  return composeSeriesGrids(
    series: series, domain: domain, plotWidth: 16, plotHeight: 5, baselineRow: 4)
}

@MainActor
private func w3Surface(
  _ style: LineChartSeriesStyle, _ points: [(Double, Double)], _ name: String
) -> [String] {
  DefaultRenderer().render(
    LineChart(
      "Trend", series: [.init("s", points: w3Points(points), style: style)], height: 6, width: 24),
    context: .init(identity: testIdentity("W3Hunt", name)),
    proposal: .init(width: 24, height: 14)
  ).rasterSurface.lines
}

/// The documented tick properties: one tick on a degenerate span or a one-cell axis, else
/// between two and `cells` ticks in strictly increasing cells from 0 to `cells - 1`, with
/// the domain's endpoint texts first and last.
private func w3TickProblem(
  _ ticks: [(cell: Int, text: String)], cells: Int, span: Double, first: String, last: String
) -> String? {
  guard span > 0, cells > 1 else {
    return ticks.count == 1 && ticks[0].cell == 0 && ticks[0].text == first
      ? nil : "single-tick axis gave \(ticks)"
  }
  guard (2...cells).contains(ticks.count) else { return "count \(ticks.count)" }
  guard zip(ticks, ticks.dropFirst()).allSatisfy({ $0.cell < $1.cell }) else {
    return "cells \(ticks.map(\.cell)) not increasing"
  }
  guard ticks.first?.cell == 0, ticks.last?.cell == cells - 1 else {
    return "ends \(ticks.map(\.cell))"
  }
  guard ticks.first?.text == first, ticks.last?.text == last else {
    return "texts \(ticks.map(\.text)) versus \(first)...\(last)"
  }
  return nil
}

/// SplitMix64 (Steele, Lea, Flood 2014): the tagged framework does not export its
/// seeded generator to child packages.
private struct W3SplitMix64 {
  var state: UInt64

  init(seed: UInt64) { state = seed }

  mutating func next() -> UInt64 {
    state &+= 0x9E37_79B9_7F4A_7C15
    var z = state
    z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
    z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
    return z ^ (z >> 31)
  }

  mutating func int(_ range: ClosedRange<Int>) -> Int {
    range.lowerBound + Int(next() % UInt64(range.count))
  }

  mutating func unit() -> Double { Double(next() >> 11) / Double(UInt64(1) << 53) }
}
