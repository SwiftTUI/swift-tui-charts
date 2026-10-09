import SwiftTUIViews

/// A compact textual timeline for ordered events or releases.
public struct Timeline: View {
  public var entries: [TimelineEntry]

  public init(_ entries: [TimelineEntry]) {
    self.entries = entries
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      ForEach(entries.indices, id: \.self) { index in
        timelineEntryView(entries[index], isLast: index == entries.count - 1)
      }
    }.accessibilityRepresentation {
      ChartDataView(
        entries.map { entry in
          .init(
            entry.title,
            detail: [entry.detail, chartDataTone(entry.tone)].compactMap { $0 }.joined(
              separator: ", "))
        }, title: "Timeline data")
    }
  }
}
