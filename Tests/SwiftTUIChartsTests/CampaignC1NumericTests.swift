import Foundation
import SwiftTUIRuntime
import Testing

@testable import SwiftTUICharts

@Suite("Campaign C1 numeric and coordinate contracts")
struct CampaignC1NumericTests {
  @Test(arguments: Array(1...20))
  func numeric(id: Int) {
    switch id {
    case 1:
      let quantum = Double.leastNonzeroMagnitude
      #expect(chartInterpolatedValue(0.25, in: 0...(quantum * 4)) == quantum)
      #expect(chartUnitFraction(quantum, in: 0...(quantum * 4)) == 0.25)
    case 2:
      let lower = 1e200
      let midpoint = lower.nextUp.nextUp
      let upper = midpoint.nextUp.nextUp
      #expect(chartUnitFraction(midpoint, in: lower...upper) == 0.5)
      #expect(chartInterpolatedValue(0.5, in: lower...upper) == midpoint)
    case 3:
      let magnitude = Double.greatestFiniteMagnitude
      let domain = (-magnitude)...(magnitude / 2)
      let value = chartInterpolatedValue(0.25, in: domain)
      #expect(value.isFinite)
      #expect(abs(chartUnitFraction(value, in: domain) - 0.25) < 1e-15)
    case 4:
      for scale in [1e-200, 1.0, 1e200] {
        #expect(abs(chartUnitFraction(scale, in: (-3 * scale)...(5 * scale)) - 0.5) < 1e-15)
        #expect(xCell(value: scale, domain: (-3 * scale)...(5 * scale), plotWidth: 9) == 4)
      }
    case 5:
      #expect(chartInterpolatedValue(-2, in: -7...19) == -7)
      #expect(chartInterpolatedValue(3, in: -7...19) == 19)
    case 6:
      let lower = 0.5
      #expect(chartUnitFraction(lower, in: lower...lower.nextUp) == 0)
      #expect(chartUnitFraction(lower.nextUp, in: lower...lower.nextUp) == 1)
    case 7:
      #expect(chartCellOffset(0.25, maximum: 10) == 3)
      #expect(chartCellOffset(0.25, maximum: 10, rounding: .down) == 2)
      #expect(chartCellOffset(0.01, maximum: 10, rounding: .awayFromZero) == 1)
    case 8:
      for fraction in [0.0, 0.2, 0.5, 1.0] {
        #expect(chartInterpolatedValue(fraction, in: -17 ... -17) == -17)
      }
    case 9:
      let series: [LineChartSeries] = [
        .init("empty", points: []),
        .init("partial", points: [.init(x: -100, y: .nan), .init(x: .infinity, y: 100)]),
        .init("a", points: [.init(x: 2, y: -3), .init(x: 4, y: 8)]),
        .init("b", points: [.init(x: -1, y: 5)]),
      ]
      #expect(plotDomain(series: series) == .init(x: -1...4, y: -3...8))
    case 10:
      let a = LineChartSeries("a", points: [.init(x: 9, y: -2), .init(x: 3, y: 7)])
      let b = LineChartSeries("b", points: [.init(x: 4, y: 0), .init(x: 1, y: 4)])
      let changed = [b, a].map { LineChartSeries($0.label, points: Array($0.points.reversed())) }
      #expect(plotDomain(series: [a, b]) == plotDomain(series: changed))
    case 11, 12:
      let axis: ChartCoordinateAxis = id == 11 ? .horizontal : .vertical
      let first = chartDomainValue(
        at: .init(x: 2.25, y: 1.75),
        in: .init(origin: .zero, size: .init(width: 10, height: 8)), domain: -9...9, axis: axis)
      let moved = chartDomainValue(
        at: .init(x: -10.75, y: 22.75),
        in: .init(origin: .init(x: -13, y: 21), size: .init(width: 10, height: 8)),
        domain: -9...9, axis: axis)
      #expect(first == moved)
    case 13, 14:
      let axis: ChartCoordinateAxis = id == 13 ? .horizontal : .vertical
      #expect(
        chartFraction(
          at: .init(x: 5.25, y: 7.25),
          in: .init(origin: .init(x: 5, y: 7), size: .init(width: 2, height: 2)), axis: axis)
          == (id == 13 ? 0.25 : 0.75))
    case 15, 16:
      let axis: ChartCoordinateAxis = id == 15 ? .horizontal : .vertical
      let rect = CellRect(origin: .init(x: 4, y: -3), size: .init(width: 8, height: 6))
      #expect(
        chartDomainValue(at: .init(x: -10, y: -10), in: rect, domain: 2...8, axis: axis)
          == (id == 15 ? 2 : 8))
      #expect(
        chartDomainValue(at: .init(x: 20, y: 20), in: rect, domain: 2...8, axis: axis)
          == (id == 15 ? 8 : 2))
    case 17:
      for length in [0, 1] {
        let rect = CellRect(origin: .zero, size: .init(width: length, height: length))
        #expect(chartFraction(at: .init(x: 4, y: 4), in: rect, axis: .horizontal) == 0)
        #expect(chartFraction(at: .init(x: 4, y: 4), in: rect, axis: .vertical) == 0)
      }
    case 18:
      let maximum = Double.greatestFiniteMagnitude
      #expect(
        chartDomainValue(
          at: .init(x: 5, y: 0),
          in: .init(origin: .zero, size: .init(width: 11, height: 3)),
          domain: -maximum...maximum, axis: .horizontal) == 0)
    case 19:
      let rect = CellRect(origin: .init(x: -2, y: 5), size: .init(width: 4, height: 4))
      #expect(chartFraction(at: .init(x: .nan, y: .infinity), in: rect, axis: .horizontal) == 0)
      #expect(chartFraction(at: .init(x: .nan, y: .infinity), in: rect, axis: .vertical) == 1)
    case 20:
      let rect = CellRect(origin: .zero, size: .init(width: 9, height: 9))
      #expect(
        chartFraction(at: .init(x: 2, y: -30), in: rect, axis: .horizontal)
          == chartFraction(at: .init(x: 2, y: 60), in: rect, axis: .horizontal))
      #expect(
        chartFraction(at: .init(x: -30, y: 2), in: rect, axis: .vertical)
          == chartFraction(at: .init(x: 60, y: 2), in: rect, axis: .vertical))
    default: Issue.record("unassigned C1 numeric scenario")
    }
  }
}
