import SwiftTUICharts
import SwiftTUIRuntime
@_spi(Testing) import SwiftTUITestSupport
import Testing

// Chart headers retain their authored names; source data is a bounded semantic
// representation independent of the painted chart height.
@MainActor
@Suite
struct ChartAccessibilityTests {
  @Test("color-independent views expose source labels and status in the visual raster")
  func redundantColorCues() {
    var environment = EnvironmentValues()
    environment.accessibilityPreferences.differentiateWithoutColor = true
    func output<V: View>(_ view: V) -> String {
      let raster = DefaultRenderer().render(
        view,
        context: .init(identity: testIdentity("color"), environmentValues: environment),
        proposal: .init(width: 80, height: 50)
      ).rasterSurface
      return raster.cells.map { String($0.map(\.character)) }.joined(separator: "\n")
    }
    let stacked = output(
      StackedBarChart(
        "Queues",
        entries: [
          .init("API", value: 8, tone: .success), .init("Jobs", value: 4, tone: .critical),
        ]))
    #expect(stacked.contains("API: 8"))
    #expect(stacked.contains("Jobs: 4"))
    #expect(stacked.contains("[Success]"))
    #expect(stacked.contains("[Critical]"))
    let threshold = output(
      ThresholdGauge(
        "Load", value: 80, total: 100,
        bands: [
          .init(upTo: 50, tone: .success), .init(upTo: 100, tone: .critical),
        ]))
    #expect(threshold.contains("Current: 80"))
    #expect(threshold.contains("Band 1 through 50"))
    #expect(threshold.contains("Band 2 through 100"))
    #expect(threshold.contains("[Critical]"))
    let legend = output(
      Legend(items: [.init("Healthy", tone: .success), .init("Failed", tone: .critical)]))
    #expect(legend.contains("Healthy [Success]"))
    #expect(legend.contains("Failed [Critical]"))
  }

  @Test(
    "selected profiles separate coincident series without changing their common scale",
    arguments: AccessibilityColorProfile.allCases)
  func separatedSeries(profile: AccessibilityColorProfile) {
    var environment = EnvironmentValues()
    environment.accessibilityPreferences.colorProfile = profile
    // The standard profile exercises the independent no-color preference.
    environment.accessibilityPreferences.differentiateWithoutColor = profile == .standard
    let snapshot = DefaultRenderer().render(
      LineChart(
        "Trend",
        series: [
          .init("Low", points: [.init(x: 0, y: 0), .init(x: 1, y: 10)], tone: .success),
          .init("High", points: [.init(x: 0, y: 90), .init(x: 1, y: 100)], tone: .critical),
        ], height: 4, width: 32
      ).chartYAxis(.values(count: 2)),
      context: .init(identity: testIdentity("sharedScale"), environmentValues: environment),
      proposal: .init(width: 40, height: 40))
    let lines = snapshot.rasterSurface.lines
    #expect(lines.filter { $0.contains("100┤") }.count == 2)
    #expect(lines.filter { $0.contains("0┼") }.count == 2)
    let output = lines.joined(separator: "\n")
    #expect(output.contains("Low") && output.contains("High"))
    #expect(output.contains("[Success]") && output.contains("[Critical]"))
    let accessible = renderLinearAccessibilityOutput(snapshot.semanticSnapshot)
    #expect(accessible.contains("LineChart data"))
    #expect(accessible.contains("Low"))
  }

  @Test("default chart headers and source values remain independently readable")
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

    #expect(output.contains("Trend"))
    #expect(output.contains("Sparkline data"))
    #expect(output.contains("Current: Sample 1, Value 1.0"))
    #expect(output.contains("Queues"))
    #expect(output.contains("BarChart data"))
    #expect(!output.contains("warning:"))
  }

  @Test("generic chart headers preserve authored names alongside source data")
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

    #expect(output.contains("Trend"))
    #expect(output.contains("Sparkline data"))
    #expect(!output.contains("warning:"))
    #expect(!output.contains("image:"))
  }
}
