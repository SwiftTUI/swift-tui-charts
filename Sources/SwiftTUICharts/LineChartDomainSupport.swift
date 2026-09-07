import SwiftTUIViews

struct LineChartDomain: Equatable, Sendable {
  var x: ClosedRange<Double>
  var y: ClosedRange<Double>
}

/// Computes the combined X and Y ranges across all series.
/// If no series contains points, this function returns `nil`.
func plotDomain(series: [LineChartSeries]) -> LineChartDomain? {
  var minX = Double.infinity
  var maxX = -Double.infinity
  var minY = Double.infinity
  var maxY = -Double.infinity
  var any = false
  for s in series {
    for p in s.points where p.x.isFinite && p.y.isFinite {
      any = true
      if p.x < minX { minX = p.x }
      if p.x > maxX { maxX = p.x }
      if p.y < minY { minY = p.y }
      if p.y > maxY { maxY = p.y }
    }
  }
  guard any else { return nil }
  return LineChartDomain(x: minX...maxX, y: minY...maxY)
}

/// Maps a domain X value to a column index in `[0, plotWidth)`.
func xCell(value: Double, domain: ClosedRange<Double>, plotWidth: Int) -> Int {
  guard plotWidth > 0 else { return 0 }
  return chartCellOffset(chartUnitFraction(value, in: domain), maximum: plotWidth - 1)
}

/// Maps a domain Y value to an inverted row index in `[0, plotHeight)`.
/// Thus, row 0 corresponds to the top of the plot.
func yCell(value: Double, domain: ClosedRange<Double>, plotHeight: Int) -> Int {
  guard domain.upperBound > domain.lowerBound, plotHeight > 0 else { return 0 }
  return chartCellOffset(1 - chartUnitFraction(value, in: domain), maximum: plotHeight - 1)
}
