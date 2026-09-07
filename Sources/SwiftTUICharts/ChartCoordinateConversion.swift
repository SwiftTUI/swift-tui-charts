import SwiftTUIViews

enum ChartCoordinateAxis: Equatable, Sendable {
  case horizontal
  case vertical
}

func chartFraction(
  at location: Point,
  in plotRect: CellRect,
  axis: ChartCoordinateAxis
) -> Double {
  let axisOrigin: Int
  let axisLength: Int
  let coordinate: Double
  switch axis {
  case .horizontal:
    axisOrigin = plotRect.origin.x
    axisLength = plotRect.size.width
    coordinate = location.x
  case .vertical:
    axisOrigin = plotRect.origin.y
    axisLength = plotRect.size.height
    coordinate = location.y
  }

  guard axisLength > 1 else {
    return 0
  }

  let minimum = Double(axisOrigin)
  let finiteCoordinate = coordinate.isFinite ? coordinate : minimum
  let fraction = min(max((finiteCoordinate - minimum) / Double(axisLength - 1), 0), 1)

  switch axis {
  case .horizontal:
    return fraction
  case .vertical:
    return 1 - fraction
  }
}

func chartDomainValue(
  at location: Point,
  in plotRect: CellRect,
  domain: ClosedRange<Double>,
  axis: ChartCoordinateAxis
) -> Double {
  let fraction = chartFraction(at: location, in: plotRect, axis: axis)
  return chartInterpolatedValue(fraction, in: domain)
}
