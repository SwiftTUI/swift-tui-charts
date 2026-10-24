import SwiftTUIRuntime
import Testing

@testable import SwiftTUICharts

@MainActor
@Suite("Campaign C1 source accessibility contracts")
struct CampaignC1AccessibilityTests {
  @Test(arguments: Array(91...100))
  func semantics(id: Int) {
    func render<V: View>(
      _ view: V, height: Int = 24,
      environment: EnvironmentValues = .init()
    ) -> RenderSnapshot {
      DefaultRenderer().render(
        view,
        context: .init(identity: testIdentity("C1", String(id)), environmentValues: environment),
        proposal: .init(width: 80, height: height))
    }
    func labels(_ snapshot: RenderSnapshot) -> [String] {
      snapshot.semanticSnapshot.accessibilityNodes.compactMap(\.label)
    }
    switch id {
    case 91:
      let snapshot = render(
        ChartDataView([.init("A", value: 1, unit: "")]).chartDataUnit("seconds"))
      #expect(labels(snapshot).contains("Current: A, Value 1.0"))
    case 92:
      let snapshot = render(ChartDataView([.init("A", value: 1)]).chartDataUnit("seconds"))
      #expect(labels(snapshot).contains("Current: A, Value 1.0, seconds"))
    case 93:
      let snapshot = render(ChartDataView([.init("Maintenance", detail: "Scheduled")]))
      #expect(labels(snapshot).contains("Current: Maintenance, Scheduled"))
      #expect(!labels(snapshot).contains { $0.contains("Value ") })
    case 94:
      let snapshot = render(ChartDataView([.init("A", value: .infinity, unit: "seconds")]))
      #expect(labels(snapshot).contains("Current: A, Missing data, seconds"))
    case 95:
      let snapshot = render(ChartDataView([.init("東京", value: 3, series: "é", detail: "🟢 ready")]))
      #expect(labels(snapshot).contains("Current: 東京, Series é, Value 3.0, 🟢 ready"))
    case 96:
      let snapshot = render(
        VStack {
          Meter("Latency", value: 1, total: 10).chartDataUnit("ms")
          Meter("Rate", value: 2, total: 10).chartDataUnit("requests")
        })
      #expect(labels(snapshot).contains("Current: Value, Value 1.0, ms"))
      #expect(labels(snapshot).contains("Current: Value, Value 2.0, requests"))
    case 97:
      let snapshot = render(Sparkline("T", values: [1.23456789, 3]), height: 1)
      #expect(labels(snapshot).contains("Current: Sample 1, Value 1.23456789"))
    case 98:
      let snapshot = render(Meter("T", value: 1.23456789, total: 10))
      #expect(labels(snapshot).contains("Current: Value, Value 1.23456789"))
      #expect(snapshot.rasterSurface.lines.joined(separator: "\n").contains("12%"))
    case 99:
      let snapshot = render(BarChart("T", entries: [.init("A", value: 3), .init("B", value: 4)]))
      #expect(snapshot.semanticSnapshot.focusRegions.isEmpty)
      #expect(labels(snapshot).contains("2 data records"))
    case 100:
      let chart = LineChart(
        "T", series: [.init("A", points: [.init(x: 0, y: 1.23456789), .init(x: 1, y: 3)])],
        height: 3, width: 20)
      let first = labels(render(chart))
      var environment = EnvironmentValues()
      environment.accessibilityPreferences.differentiateWithoutColor = true
      let changed = labels(render(chart, environment: environment))
      let selected: (String) -> Bool = { $0.hasPrefix("Current:") || $0.hasSuffix(" data records") }
      #expect(first.filter(selected) == changed.filter(selected))
      #expect(changed.contains { $0.contains("Value 1.23456789") })
    default: Issue.record("unassigned C1 accessibility scenario")
    }
  }
}
