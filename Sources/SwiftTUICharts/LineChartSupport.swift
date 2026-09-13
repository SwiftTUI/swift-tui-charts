import SwiftTUIViews

@MainActor
@ViewBuilder
func lineChartBody(
  series: [LineChartSeries],
  height: Int,
  width: Int,
  xAxis: LineChartXAxis,
  yAxis: LineChartYAxis,
  legend: LineChartLegendConfig,
  baseline: LineChartBaseline
) -> some View {
  let yAxisLabelWidth = yAxis.isHidden ? 0 : 6
  let yAxisChromeWidth = yAxis.isHidden ? 0 : 2
  let plotWidth = max(1, width - yAxisLabelWidth - yAxisChromeWidth)
  let plotHeight = max(1, height)

  let domainOrNil = plotDomain(series: series)
  let domain = domainOrNil ?? LineChartDomain(x: 0...1, y: 0...1)

  let yTicks = yAxisTickLabels(
    domain: domain.y,
    ticks: yAxis.ticks,
    format: yAxis.format,
    plotHeight: plotHeight
  )
  let xTicks = xAxisTickLabels(
    domain: domain.x,
    ticks: xAxis.ticks,
    format: xAxis.format,
    plotWidth: plotWidth
  )

  let baselineRow: Int = {
    switch baseline {
    case .zero:
      return yCell(value: 0, domain: domain.y, plotHeight: plotHeight)
    case .auto:
      return plotHeight - 1
    }
  }()

  let composed = composeSeriesGrids(
    series: series,
    domain: domain,
    plotWidth: plotWidth,
    plotHeight: plotHeight,
    baselineRow: baselineRow
  )
  let composedGrid = composed.grid
  let cellSeriesIndex = composed.seriesIndex
  let tones = series.map {
    $0.tone == .automatic ? AnyShapeStyle(.tint) : metricAccentStyle(for: $0.tone)
  }

  VStack(alignment: .leading, spacing: 0) {
    if legend.position == .top {
      legendStrip(series: series, spacing: legend.itemSpacing)
    }
    ForEach(0..<plotHeight, id: \.self) { row in
      HStack(alignment: .center, spacing: 0) {
        if !yAxis.isHidden {
          let yLabel = yTicks.first(where: { $0.row == row })?.text ?? ""
          Text(yLabel)
            .frame(width: yAxisLabelWidth, alignment: .trailing)
            .foregroundStyle(.separator)
          Text(row == baselineRow ? "┼" : "┤")
            .foregroundStyle(.separator)
        }
        lineChartRow(composedGrid[row], seriesIndices: cellSeriesIndex[row], tones: tones)
      }
    }
    HStack(alignment: .center, spacing: 0) {
      Text(String(repeating: " ", count: yAxisLabelWidth))
      if !yAxis.isHidden {
        Text("┼")
          .foregroundStyle(.separator)
      }
      Text(String(repeating: "─", count: plotWidth))
        .foregroundStyle(.separator)
    }
    if !xAxis.isHidden {
      HStack(alignment: .center, spacing: 0) {
        Text(String(repeating: " ", count: yAxisLabelWidth + (yAxis.isHidden ? 0 : 1)))
        Text(formatXAxisLine(xTicks: xTicks, plotWidth: plotWidth))
          .foregroundStyle(.separator)
      }
    }
    if legend.position == .bottom {
      legendStrip(series: series, spacing: legend.itemSpacing)
    }
  }
}

// One public rich Text value per plot row keeps glyph/style runs in the text
// payload instead of resolving a view and identity for every chart cell.
@MainActor
private func lineChartRow(
  _ cells: [LineRasterCell?], seriesIndices: [Int?], tones: [AnyShapeStyle]
) -> Text {
  var interpolation = Text.StringInterpolation(
    literalCapacity: cells.count, interpolationCount: cells.count)
  var run = ""
  var previousStyle: AnyShapeStyle?
  for column in cells.indices {
    let style =
      seriesIndices[column].flatMap { tones.indices.contains($0) ? tones[$0] : nil }
      ?? AnyShapeStyle(.separator)
    if let previousStyle, previousStyle != style {
      interpolation.appendInterpolation(Text(run).foregroundStyle(previousStyle))
      run = ""
    }
    run.append(cells[column]?.glyph ?? " ")
    previousStyle = style
  }
  if let previousStyle {
    interpolation.appendInterpolation(Text(run).foregroundStyle(previousStyle))
  }
  return Text(Text.RichContent(stringInterpolation: interpolation))
}

private func formatXAxisLine(xTicks: [AxisTickLabel], plotWidth: Int) -> String {
  var line = Array(repeating: Character(" "), count: plotWidth)
  for tick in xTicks {
    let text = Array(tick.text)
    let start = max(0, tick.col - text.count / 2)
    for (i, ch) in text.enumerated() {
      let position = start + i
      guard position < plotWidth else { break }
      line[position] = ch
    }
  }
  return String(line)
}

@MainActor
@ViewBuilder
private func legendStrip(series: [LineChartSeries], spacing: Int) -> some View {
  HStack(alignment: .center, spacing: spacing) {
    ForEach(series.indices, id: \.self) { index in
      let toneStyle =
        series[index].tone == .automatic
        ? AnyShapeStyle(.tint)
        : metricAccentStyle(for: series[index].tone)
      HStack(alignment: .center, spacing: 1) {
        Text("●").foregroundStyle(toneStyle)
        Text(series[index].label).foregroundStyle(.foreground)
      }
    }
  }
}
