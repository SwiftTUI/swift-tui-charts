/// One rasterized cell in a line chart plot grid.
struct LineRasterCell: Equatable, Sendable {
  /// Uses `•` for isolated points and `│`/`─`/`╭`/`╮`/`╰`/`╯` for connector segments.
  /// `dataPointGlyph(...)` and `elbowGlyph(...)` select the glyph.
  var glyph: Character
}

/// Maps a series of `(x, y)` points into a `plotHeight × plotWidth` grid.
/// Points retain authored order; nonfinite points break the line into separate runs.
/// Consecutive samples in one cell draw as one sample, so glyphs read their arrival and
/// departure from the nearest distinct neighbours.
func rasterizeLine(
  points: [LineChartPoint],
  domain: LineChartDomain,
  plotWidth: Int,
  plotHeight: Int
) -> [[LineRasterCell?]] {
  let width = max(1, plotWidth)
  let height = max(1, plotHeight)
  var grid: [[LineRasterCell?]] = Array(
    repeating: Array(repeating: nil, count: width),
    count: height
  )

  guard !points.isEmpty else { return grid }

  if points.count == 1, points[0].x.isFinite, points[0].y.isFinite {
    let p = points[0]
    let col = xCell(value: p.x, domain: domain.x, plotWidth: width)
    let row = yCell(value: p.y, domain: domain.y, plotHeight: height)
    grid[row][col] = LineRasterCell(glyph: "•")
    return grid
  }

  let cells = plotCells(points: points, domain: domain, plotWidth: width, plotHeight: height)

  for i in 0..<(cells.count - 1) {
    if let from = cells[i], let to = cells[i + 1] {
      drawSegment(from: from, to: to, into: &grid)
    }
  }

  for i in 0..<cells.count {
    guard let current = cells[i] else { continue }
    let previous = i > 0 ? cells[i - 1] : nil
    let next = i + 1 < cells.count ? cells[i + 1] : nil
    grid[current.row][current.col] = LineRasterCell(
      glyph: dataPointGlyph(current: current, previous: previous, next: next)
    )
  }

  return grid
}

/// Maps samples to cells; `nil` marks a nonfinite sample, which breaks the run.
/// A sample in the same cell as its predecessor adds no connector and no direction (an exact
/// duplicate, which `LineChartSeries` accepts in authored order, or a sample that quantizes
/// into that cell), so each run of coincident cells collapses to one. Gaps are kept, so runs
/// never merge across one, and a non-adjacent revisit of a cell keeps its authored place.
private func plotCells(
  points: [LineChartPoint],
  domain: LineChartDomain,
  plotWidth: Int,
  plotHeight: Int
) -> [(col: Int, row: Int)?] {
  var cells: [(col: Int, row: Int)?] = []
  cells.reserveCapacity(points.count)
  for p in points {
    guard p.x.isFinite, p.y.isFinite else {
      cells.append(nil)
      continue
    }
    let cell = (
      col: xCell(value: p.x, domain: domain.x, plotWidth: plotWidth),
      row: yCell(value: p.y, domain: domain.y, plotHeight: plotHeight)
    )
    if let last = cells.last, let previous = last, previous == cell { continue }
    cells.append(cell)
  }
  return cells
}

private func drawSegment(
  from: (col: Int, row: Int),
  to: (col: Int, row: Int),
  into grid: inout [[LineRasterCell?]]
) {
  if from.row == to.row {
    let colStart = min(from.col, to.col)
    let colEnd = max(from.col, to.col)
    for col in colStart...colEnd where grid[from.row][col] == nil {
      grid[from.row][col] = LineRasterCell(glyph: "─")
    }
    return
  }
  if from.col == to.col {
    let rowStart = min(from.row, to.row)
    let rowEnd = max(from.row, to.row)
    for row in rowStart...rowEnd where grid[row][from.col] == nil {
      grid[row][from.col] = LineRasterCell(glyph: "│")
    }
    return
  }

  let goingRight = to.col > from.col
  let goingDown = to.row > from.row

  let hStart = goingRight ? from.col + 1 : to.col
  let hEnd = goingRight ? to.col : from.col - 1
  if hStart <= hEnd {
    for col in hStart...hEnd where grid[from.row][col] == nil {
      grid[from.row][col] = LineRasterCell(
        glyph: col == to.col
          ? elbowGlyph(goingRight: goingRight, goingDown: goingDown)
          : "─"
      )
    }
  }

  let vStart = min(from.row, to.row) + 1
  let vEnd = max(from.row, to.row) - 1
  if vStart <= vEnd {
    for row in vStart...vEnd where grid[row][to.col] == nil {
      grid[row][to.col] = LineRasterCell(glyph: "│")
    }
  }
}

private func elbowGlyph(goingRight: Bool, goingDown: Bool) -> Character {
  switch (goingRight, goingDown) {
  case (true, true): "╮"
  case (true, false): "╯"
  case (false, true): "╭"
  case (false, false): "╰"
  }
}

private func dataPointGlyph(
  current: (col: Int, row: Int),
  previous: (col: Int, row: Int)?,
  next: (col: Int, row: Int)?
) -> Character {
  guard previous != nil || next != nil else { return "•" }

  if previous == nil, let next {
    if next.row == current.row { return "─" }
    // `drawSegment` leaves the source horizontally toward the next sample's column,
    // so a descending-X source opens left, mirroring the ascending glyphs.
    if next.col < current.col { return next.row > current.row ? "╮" : "╯" }
    return next.row > current.row ? "╭" : "╰"
  }

  if let previous, next == nil {
    if previous.row == current.row { return "─" }
    // `drawSegment` puts a segment's vertical run in the *destination*
    // column, so the final sample is always fed from directly above or
    // below — never from its left. Open toward that vertical, matching
    // the `exitRight` half of the interior-sample table below.
    return previous.row > current.row ? "╭" : "╰"
  }

  guard let previous, let next else { return "•" }

  // `drawSegment` draws a segment to an equal-column successor as a vertical run in
  // this column, so the sample leaves vertically. Every other successor is left
  // horizontally, which the table below covers.
  if next.col == current.col, next.row != current.row {
    if previous.row != current.row { return "│" }
    if previous.col != current.col {
      switch (previous.col < current.col, next.row > current.row) {
      case (true, true): return "╮"
      case (true, false): return "╯"
      case (false, true): return "╭"
      case (false, false): return "╰"
      }
    }
  }

  let exitRight = next.col > current.col
  if previous.row == current.row {
    return "─"
  }
  let comeFromAbove = previous.row < current.row
  switch (exitRight, comeFromAbove) {
  case (true, true): return "╰"
  case (true, false): return "╭"
  case (false, true): return "╯"
  case (false, false): return "╮"
  }
}

/// Renders the `.area` style.
/// It fills every cell between the line and `baselineRow` with `▒`, on whichever side of the
/// baseline the line lies: down from a line above it and up from a line below it.
/// Then it draws the line on top.
func rasterizeArea(
  points: [LineChartPoint],
  domain: LineChartDomain,
  plotWidth: Int,
  plotHeight: Int,
  baselineRow: Int
) -> [[LineRasterCell?]] {
  let lineGrid = rasterizeLine(
    points: points,
    domain: domain,
    plotWidth: plotWidth,
    plotHeight: plotHeight
  )
  var grid = lineGrid
  let height = max(1, plotHeight)
  let width = max(1, plotWidth)
  let clampedBaseline = min(max(baselineRow, 0), height - 1)

  for col in 0..<width {
    guard let topRow = (0..<height).first(where: { lineGrid[$0][col] != nil }),
      let bottomRow = (0..<height).last(where: { lineGrid[$0][col] != nil })
    else { continue }
    let fillStart = min(topRow, clampedBaseline)
    let fillEnd = max(bottomRow, clampedBaseline)
    for row in fillStart...fillEnd where grid[row][col] == nil {
      grid[row][col] = LineRasterCell(glyph: "▒")
    }
  }
  return grid
}

/// Renders the `.step` style.
/// It draws a horizontal segment from each sample to the next sample column.
/// It does not include the next sample column in this segment.
/// Then it draws a vertical segment to the new Y value in that column.
/// Consecutive samples in one cell draw as one sample.
func rasterizeStep(
  points: [LineChartPoint],
  domain: LineChartDomain,
  plotWidth: Int,
  plotHeight: Int
) -> [[LineRasterCell?]] {
  let width = max(1, plotWidth)
  let height = max(1, plotHeight)
  var grid: [[LineRasterCell?]] = Array(
    repeating: Array(repeating: nil, count: width),
    count: height
  )

  guard !points.isEmpty else { return grid }

  let cells = plotCells(points: points, domain: domain, plotWidth: width, plotHeight: height)

  for i in 0..<cells.count {
    guard let here = cells[i] else { continue }
    let next = i + 1 < cells.count ? cells[i + 1] : nil
    let endCol = next?.col ?? (i + 1 == cells.count ? width : here.col + 1)
    let columns = endCol >= here.col ? here.col..<endCol : (endCol + 1)..<(here.col + 1)
    for col in columns where grid[here.row][col] == nil {
      grid[here.row][col] = LineRasterCell(glyph: "─")
    }
    if let next {
      let rowStart = min(here.row, next.row)
      let rowEnd = max(here.row, next.row)
      for row in rowStart...rowEnd where grid[row][endCol] == nil {
        grid[row][endCol] = LineRasterCell(glyph: "│")
      }
    }
  }
  return grid
}
