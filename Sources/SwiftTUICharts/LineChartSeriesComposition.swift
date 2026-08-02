struct ComposedSeriesGrid: Equatable, Sendable {
  /// The rasterized cells across all series.
  /// Later series replace earlier series after the renderer paints the area fills.
  var grid: [[LineRasterCell?]]
  /// The index in `series` for the series that owns each filled cell.
  /// The view layer uses this index to select the tone.
  var seriesIndex: [[Int?]]
}

/// Composites all series in z-order. It first draws the areas for all `.area` series.
/// Then it draws lines and steps in declaration order, including the lines for areas.
/// If cells collide, the later series replaces the earlier series.
func composeSeriesGrids(
  series: [LineChartSeries],
  domain: LineChartDomain,
  plotWidth: Int,
  plotHeight: Int,
  baselineRow: Int
) -> ComposedSeriesGrid {
  let width = max(1, plotWidth)
  let height = max(1, plotHeight)
  var grid: [[LineRasterCell?]] = Array(
    repeating: Array(repeating: nil, count: width),
    count: height
  )
  var seriesIndex: [[Int?]] = Array(
    repeating: Array(repeating: nil, count: width),
    count: height
  )

  for (index, s) in series.enumerated() where s.style == .area {
    let g = rasterizeArea(
      points: s.points, domain: domain,
      plotWidth: width, plotHeight: height,
      baselineRow: baselineRow
    )
    for row in 0..<height {
      for col in 0..<width where g[row][col] != nil {
        grid[row][col] = g[row][col]
        seriesIndex[row][col] = index
      }
    }
  }

  for (index, s) in series.enumerated() {
    let g: [[LineRasterCell?]]
    switch s.style {
    case .line, .area:
      g = rasterizeLine(
        points: s.points, domain: domain,
        plotWidth: width, plotHeight: height
      )
    case .step:
      g = rasterizeStep(
        points: s.points, domain: domain,
        plotWidth: width, plotHeight: height
      )
    }
    for row in 0..<height {
      for col in 0..<width where g[row][col] != nil {
        grid[row][col] = g[row][col]
        seriesIndex[row][col] = index
      }
    }
  }

  return ComposedSeriesGrid(grid: grid, seriesIndex: seriesIndex)
}
