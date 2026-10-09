import SwiftTUIViews

/// A stacked bar chart for segmented totals.
public struct StackedBarChart<Label: View, Summary: View>: View {
  public var entries: [BarChartEntry]
  public var total: Double?
  public var barWidth: Int
  private let label: Label
  private let summary: Summary
  private let accessibilitySummary: String?
  @Environment(\.accessibilityPreferences) private var colorPreferences

  public init(
    entries: [BarChartEntry],
    total: Double? = nil,
    barWidth: Int = 16,
    @ViewBuilder label: () -> Label,
    @ViewBuilder summary: () -> Summary
  ) {
    self.init(
      entries: entries,
      total: total,
      barWidth: barWidth,
      accessibilitySummary: nil,
      label: label,
      summary: summary
    )
  }

  private init(
    entries: [BarChartEntry],
    total: Double?,
    barWidth: Int,
    accessibilitySummary: String?,
    @ViewBuilder label: () -> Label,
    @ViewBuilder summary: () -> Summary
  ) {
    self.entries = entries
    self.total = total
    self.barWidth = barWidth
    self.label = label()
    self.summary = summary()
    self.accessibilitySummary = accessibilitySummary
  }

  public var body: some View {
    let effectiveTotal = stackedBarEffectiveTotal(entries, total: total)

    VStack(alignment: .leading, spacing: 0) {
      chartHeader(label: label, summary: summary, accessibilitySummary: accessibilitySummary)
      VStack(alignment: .leading, spacing: 0) {
        if chartUsesColorCues(colorPreferences) {
          // A labeled row per segment preserves arbitrarily many categories;
          // a repeating finite symbol palette would make larger sets ambiguous.
          ForEach(entries.indices, id: \.self) { index in
            Text("\(entries[index].label): \(metricValueString(entries[index].value))")
            ChartToneCue(tone: entries[index].tone)
            stackedBarTrackView([entries[index]], total: effectiveTotal, barWidth: barWidth)
          }
        } else {
          stackedBarTrackView(entries, total: effectiveTotal, barWidth: barWidth)
        }
      }.accessibilityRepresentation {
        ChartDataView(
          barChartData(entries) + [
            .init("Displayed total", value: stackedBarEffectiveTotal(entries, total: total))
          ], title: "StackedBarChart data")
      }
    }
  }
}

extension StackedBarChart where Label == EmptyView, Summary == Text {
  public init(
    entries: [BarChartEntry],
    total: Double? = nil,
    barWidth: Int = 16
  ) {
    let summary = stackedBarSummaryText(entries, total: total)
    self.init(
      entries: entries,
      total: total,
      barWidth: barWidth,
      accessibilitySummary: summary,
      label: { EmptyView() },
      summary: { Text(summary) }
    )
  }
}

extension StackedBarChart where Label == Text, Summary == Text {
  public init<S: StringProtocol>(
    _ title: S,
    entries: [BarChartEntry],
    total: Double? = nil,
    barWidth: Int = 16
  ) {
    let title = String(title)
    let summary = stackedBarSummaryText(entries, total: total)
    self.init(
      entries: entries,
      total: total,
      barWidth: barWidth,
      accessibilitySummary: chartAccessibilityLabel(title: title, summary: summary),
      label: { Text(title) },
      summary: { Text(summary) }
    )
  }
}
