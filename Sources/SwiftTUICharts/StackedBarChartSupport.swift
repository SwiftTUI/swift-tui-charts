import SwiftTUIViews

// Stacked-bar-chart helpers: effective total and summary derivation, the
// largest-remainder width apportionment that distributes a fixed bar width
// across segments, and the stacked track renderer.
//
// Split out of `ChartSupport.swift` so that file is not a catch-all for every
// chart family.

func stackedBarEffectiveTotal(
  _ entries: [BarChartEntry],
  total: Double?
) -> Double {
  max(1, total ?? entries.reduce(0) { $0 + abs($1.value) })
}

func stackedBarSummaryText(
  _ entries: [BarChartEntry],
  total: Double?
) -> String {
  "sum \(metricValueString(stackedBarEffectiveTotal(entries, total: total)))"
}

func stackedBarWidths(
  entries: [BarChartEntry],
  total: Double,
  barWidth: Int
) -> [Int] {
  let effectiveBarWidth = max(1, barWidth)
  guard !entries.isEmpty else {
    return []
  }

  let rawWeights = entries.map { $0.value.isFinite ? abs($0.value) : 0 }
  guard let scale = rawWeights.max(), scale > 0 else {
    return Array(repeating: 0, count: entries.count)
  }
  let weights = rawWeights.map { $0 / scale }
  let totalWeight = weights.reduce(0, +)
  guard totalWeight > 0 else {
    return Array(repeating: 0, count: entries.count)
  }

  var widths = Array(repeating: 0, count: entries.count)
  var remainders: [(index: Int, value: Double)] = []
  var assigned = 0
  let denominator = max(total.isFinite ? total / scale : totalWeight, totalWeight)
  let positiveCount = weights.count { $0 > 0 }
  let allocatedWidth = max(
    min(positiveCount, effectiveBarWidth),
    chartCellOffset(totalWeight / denominator, maximum: effectiveBarWidth)
  )

  for index in entries.indices {
    let fraction = weights[index] / denominator
    let rawWidth = fraction * Double(effectiveBarWidth)
    let baseWidth = chartCellOffset(fraction, maximum: effectiveBarWidth, rounding: .down)
    widths[index] = baseWidth
    assigned += baseWidth
    if weights[index] > 0 {
      remainders.append((index, rawWidth - Double(baseWidth)))
    }
  }

  for index in entries.indices
  where weights[index] > 0 && widths[index] == 0 && assigned < allocatedWidth {
    widths[index] = 1
    assigned += 1
  }

  if assigned < allocatedWidth {
    for remainder in remainders.sorted(by: { $0.value > $1.value })
    where assigned < allocatedWidth {
      widths[remainder.index] += 1
      assigned += 1
    }
  } else if assigned > allocatedWidth {
    for remainder in remainders.sorted(by: { $0.value < $1.value })
    where assigned > allocatedWidth {
      guard widths[remainder.index] > 0 else {
        continue
      }
      widths[remainder.index] -= 1
      assigned -= 1
    }
  }

  return widths
}

@MainActor
@ViewBuilder
func stackedBarTrackView(
  _ entries: [BarChartEntry],
  total: Double,
  barWidth: Int
) -> some View {
  let effectiveBarWidth = max(1, barWidth)
  let widths = stackedBarWidths(
    entries: entries,
    total: total,
    barWidth: effectiveBarWidth
  )
  let assignedWidth = widths.reduce(0, +)

  HStack(alignment: .center, spacing: 0) {
    ForEach(entries.indices, id: \.self) { index in
      let accentStyle =
        entries[index].tone == .automatic
        ? AnyShapeStyle(.tint)
        : metricAccentStyle(for: entries[index].tone)

      if widths[index] > 0 {
        Text(String(repeating: "█", count: widths[index]))
          .foregroundStyle(accentStyle)
      }
    }
    if assignedWidth < effectiveBarWidth {
      Text(String(repeating: "─", count: effectiveBarWidth - assignedWidth))
        .foregroundStyle(.separator)
    }
  }
}
