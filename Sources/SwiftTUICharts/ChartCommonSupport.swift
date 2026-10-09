import SwiftTUIViews

// Cross-cutting chart helpers shared by every chart family, plus the two
// standalone row renderers (`timelineEntryView`, `legendItemView`) that are
// not tied to a bar/column/gauge family.
//
// Split out of `ChartSupport.swift` so the per-family support files
// (`ComparisonChartSupport`, `StackedBarChartSupport`, …) and the remaining
// bar/column/heat-strip helpers each stay focused on one chart family.

@MainActor
func isEmptyView<V: View>(
  _ view: V
) -> Bool {
  let erased: Any = view
  return erased is EmptyView
}

@MainActor
@ViewBuilder
func chartHeader<Label: View, Summary: View>(
  label: Label,
  summary: Summary,
  accessibilitySummary: String? = nil
) -> some View {
  if !isEmptyView(label) || !isEmptyView(summary) {
    HStack(alignment: .center, spacing: 1) {
      if !isEmptyView(label) {
        label
          .foregroundStyle(.terminalBorder(.accent))
      }
      if !isEmptyView(summary) {
        Spacer()
        summary
          .foregroundStyle(.separator)
      }
    }.semanticMetadata(
      .init(
        accessibilityRole: accessibilitySummary == nil ? nil : .group,
        accessibilityLabel: accessibilitySummary))
  }
}

func chartAccessibilityLabel(
  title: String? = nil,
  summary: String
) -> String {
  guard let title, !title.isEmpty else {
    return summary
  }
  guard !summary.isEmpty else {
    return title
  }
  return "\(title): \(summary)"
}

@MainActor
@ViewBuilder
func timelineEntryView(
  _ entry: TimelineEntry,
  isLast: Bool
) -> some View {
  let accentStyle = metricAccentStyle(for: entry.tone)

  if let detail = entry.detail {
    HStack(alignment: .top, spacing: 1) {
      VStack(alignment: .leading, spacing: 0) {
        Text(isLast ? "╰" : "├")
          .foregroundStyle(accentStyle)
        Text(isLast ? " " : "│")
          .foregroundStyle(.separator)
      }
      VStack(alignment: .leading, spacing: 0) {
        Text(entry.title)
          .lineLimit(1)
        ChartToneCue(tone: entry.tone)
        Text(detail)
          .foregroundStyle(.separator)
          .lineLimit(1)
      }
    }
  } else {
    HStack(alignment: .top, spacing: 1) {
      Text(isLast ? "╰" : "├")
        .foregroundStyle(accentStyle)
      Text(entry.title)
        .lineLimit(1)
      ChartToneCue(tone: entry.tone)
    }
  }
}

@MainActor
@ViewBuilder
func legendItemView(
  _ item: LegendItem
) -> some View {
  let accentStyle =
    item.tone == .automatic
    ? AnyShapeStyle(.tint)
    : metricAccentStyle(for: item.tone)

  HStack(alignment: .center, spacing: 1) {
    Text("■")
      .foregroundStyle(accentStyle)
    Text(item.label)
      .foregroundStyle(.foreground)
    ChartToneCue(tone: item.tone)
  }
}
