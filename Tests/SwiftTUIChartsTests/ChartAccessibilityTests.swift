import SwiftTUICharts
import SwiftTUIRuntime
@_spi(Testing) import SwiftTUITestSupport
import Testing

// Chart accessibility contract: default titled charts reach assistive output
// as labeled images; label-less custom charts surface the framework's
// missing-label diagnostic instead of silently disappearing.
@MainActor
@Suite
struct ChartAccessibilityTests {
  @Test("default chart summaries provide image accessibility labels")
  func defaultChartSummariesProvideImageAccessibilityLabels() {
    let artifacts = DefaultRenderer().render(
      VStack(alignment: .leading, spacing: 0) {
        Sparkline("Trend", values: [1, 3, 2])
        BarChart(
          "Queues",
          entries: [
            .init("api", value: 8),
            .init("jobs", value: 4),
          ]
        )
      },
      context: ResolveContext(identity: testIdentity("ChartAccessibilityRoot")),
      proposal: .init(width: 40, height: 8)
    )

    let output = renderLinearAccessibilityOutput(artifacts.semanticSnapshot)

    #expect(output.contains("image: Trend: lo 1 hi 3"))
    #expect(output.contains("image: Queues: max 8"))
    #expect(!output.contains("warning:"))
  }

  @Test("custom chart content without accessibility label emits a warning")
  func customChartWithoutAccessibilityLabelEmitsWarning() {
    let artifacts = DefaultRenderer().render(
      Sparkline(
        values: [1, 3, 2],
        label: { Text("Trend") },
        summary: { EmptyView() }
      ),
      context: ResolveContext(identity: testIdentity("CustomChartAccessibilityRoot")),
      proposal: .init(width: 40, height: 4)
    )

    let output = renderLinearAccessibilityOutput(artifacts.semanticSnapshot)

    #expect(
      output.contains(
        "warning: Sparkline omitted from accessibility output; add accessibilityLabel(...) or accessibilityHidden(true)."
      )
    )
    #expect(!output.contains("image:"))
  }
}
