import SwiftTUICharts
import SwiftTUIRuntime
@_spi(Testing) import SwiftTUITestSupport
import Testing

@MainActor
@Suite
struct ChartDataViewTests {
  @Test(
    "semantic data has bounded output at one-row chart heights", arguments: [3, 1_000, 100_000])
  func boundedRepresentation(count: Int) throws {
    let artifacts = DefaultRenderer().render(
      Sparkline("Traffic", values: (0..<count).map(Double.init)).chartDataUnit("requests"),
      context: ResolveContext(identity: testIdentity("BoundedChartData")),
      proposal: .init(width: 40, height: 2))
    let nodes = artifacts.semanticSnapshot.accessibilityNodes
    let position = try #require(nodes.first { $0.label == "Data position" })
    #expect(position.control?.minimum == 1)
    #expect(position.control?.maximum == Double(count))
    #expect(position.control?.value == .number(1))
    #expect(position.properties?.valueDescription == "Sample 1, Value 0.0, requests")
    #expect(nodes.count < 40)
    #expect(artifacts.semanticSnapshot.focusRegions.isEmpty)
    #expect(nodes.contains { $0.label == "Current: Sample 1, Value 0.0, requests" })
  }

  @Test("empty, missing and precise source records retain their meaning")
  func sourceMeaning() throws {
    let empty = DefaultRenderer().render(
      ChartDataView([]),
      context: ResolveContext(identity: testIdentity("EmptyData")),
      proposal: .init(width: 40, height: 12))
    #expect(empty.semanticSnapshot.accessibilityNodes.contains { $0.label == "No data" })
    #expect(!empty.semanticSnapshot.accessibilityNodes.contains { $0.label == "Data position" })
    let missing = DefaultRenderer().render(
      ChartDataView([.init("Missing", value: .nan)]),
      context: ResolveContext(identity: testIdentity("MissingData")),
      proposal: .init(width: 40, height: 12))
    #expect(
      missing.semanticSnapshot.accessibilityNodes.contains {
        $0.label == "Current: Missing, Missing data"
      })
    let exact = DefaultRenderer().render(
      ChartDataView([
        .init("Monday", value: 1.23456789, series: "Traffic", detail: "Measured", unit: "requests")
      ]).chartDataUnit("ignored"),
      context: ResolveContext(identity: testIdentity("ExactData")),
      proposal: .init(width: 60, height: 12))
    #expect(
      exact.semanticSnapshot.accessibilityNodes.contains {
        $0.label == "Current: Monday, Series Traffic, Value 1.23456789, requests, Measured"
      })
  }
}
