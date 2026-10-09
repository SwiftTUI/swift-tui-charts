import SwiftTUIViews

/// A gauge that changes tone across authored threshold bands.
public struct ThresholdGauge<Label: View, Summary: View>: View {
  public var value: Double
  public var total: Double
  public var bands: [ThresholdBand]
  public var barWidth: Int
  private let label: Label
  private let summary: Summary
  private let accessibilitySummary: String?
  @Environment(\.accessibilityPreferences) private var colorPreferences

  public init(
    value: Double,
    total: Double,
    bands: [ThresholdBand],
    barWidth: Int = 12,
    @ViewBuilder label: () -> Label,
    @ViewBuilder summary: () -> Summary
  ) {
    self.init(
      value: value,
      total: total,
      bands: bands,
      barWidth: barWidth,
      accessibilitySummary: nil,
      label: label,
      summary: summary
    )
  }

  private init(
    value: Double,
    total: Double,
    bands: [ThresholdBand],
    barWidth: Int,
    accessibilitySummary: String?,
    @ViewBuilder label: () -> Label,
    @ViewBuilder summary: () -> Summary
  ) {
    self.value = value
    self.total = total
    self.bands = bands
    self.barWidth = barWidth
    self.label = label()
    self.summary = summary()
    self.accessibilitySummary = accessibilitySummary
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      chartHeader(label: label, summary: summary, accessibilitySummary: accessibilitySummary)
      VStack(alignment: .leading, spacing: 0) {
        thresholdGaugeTrackView(
          value: value,
          total: total,
          bands: bands,
          barWidth: barWidth
        )
        if chartUsesColorCues(colorPreferences) {
          Text("Current: \(metricValueString(value))")
          ChartToneCue(tone: thresholdBandTone(for: value, total: total, bands: bands))
          let displayedBands = thresholdBandsSorted(bands, total: total)
          ForEach(displayedBands.indices, id: \.self) { index in
            HStack(spacing: 1) {
              Text(
                "Band \(index + 1) through \(metricValueString(displayedBands[index].upperBound))")
              ChartToneCue(tone: displayedBands[index].tone)
            }
          }
        }
      }.accessibilityRepresentation {
        ChartDataView(
          thresholdChartData(value: value, total: total, bands: bands), title: "ThresholdGauge data"
        )
      }
    }
  }
}

extension ThresholdGauge where Label == EmptyView, Summary == Text {
  public init(
    value: Double,
    total: Double,
    bands: [ThresholdBand],
    barWidth: Int = 12
  ) {
    let summary = progressSummaryText(value: value, total: total)
    self.init(
      value: value,
      total: total,
      bands: bands,
      barWidth: barWidth,
      accessibilitySummary: summary,
      label: { EmptyView() },
      summary: { Text(summary) }
    )
  }
}

extension ThresholdGauge where Label == Text, Summary == Text {
  public init<S: StringProtocol>(
    _ title: S,
    value: Double,
    total: Double,
    bands: [ThresholdBand],
    barWidth: Int = 12
  ) {
    let title = String(title)
    let summary = progressSummaryText(value: value, total: total)
    self.init(
      value: value,
      total: total,
      bands: bands,
      barWidth: barWidth,
      accessibilitySummary: chartAccessibilityLabel(title: title, summary: summary),
      label: { Text(title) },
      summary: { Text(summary) }
    )
  }
}
