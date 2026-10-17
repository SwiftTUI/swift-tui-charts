import Foundation
import SwiftTUIRuntime
import Testing

@testable import SwiftTUICharts

@MainActor
struct DenseDashboardQualificationTests {
  @Test("STUI-302: dense public line charts retain raster profiles and accessible summaries")
  func denseDashboards() {
    for size in [CellSize(width: 80, height: 24), CellSize(width: 160, height: 60)] {
      for seriesCount in [1, 8, 32] {
        let series = (0..<seriesCount).map { index in
          LineChartSeries(
            "Series \(index)",
            points: (0..<64).map { x in
              LineChartPoint(x: Double(x), y: sin(Double(x + index * 3) / 7) * Double(index + 1))
            }, style: index % 3 == 0 ? .area : index % 3 == 1 ? .line : .step,
            tone: index.isMultiple(of: 2) ? .automatic : .success)
        }
        let chart = LineChart(
          series: series, height: size.height - 5, width: size.width,
          label: { Text("Dense dashboard") }, summary: { Text("\(seriesCount) streams") }
        )
        .chartLegend(.hidden)
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        let renderer = DefaultRenderer()
        var durations: [Double] = []
        var snapshot: RenderSnapshot?
        for _ in 0..<3 {
          let start = ContinuousClock.now
          snapshot = renderer.render(
            chart, context: .init(identity: Identity(components: ["dense"])),
            proposal: .init(width: size.width, height: size.height))
          let elapsed = start.duration(to: .now).components
          durations.append(Double(elapsed.seconds) * 1_000 + Double(elapsed.attoseconds) / 1e15)
        }
        guard let snapshot else {
          Issue.record("missing snapshot")
          return
        }
        let hashes = RenderedTextFixtureTerminalConfiguration.supported.map { configuration in
          let output = TerminalSurfaceRenderer(capabilityProfile: configuration.capabilityProfile)
            .render(snapshot.rasterSurface)
          return output.utf8.reduce(UInt64(0xcbf2_9ce4_8422_2325)) {
            ($0 ^ UInt64($1)) &* 0x100_0000_01b3
          }
        }
        #expect(snapshot.rasterSurface.size == size)
        let key = "\(size.width)x\(size.height)/\(seriesCount)"
        #expect(hashes == Self.expectedRasterHashes[key])
        #expect(snapshot.diagnostics.counts.resolvedNodes < size.width * size.height / 4)
        let nodes = snapshot.semanticSnapshot.accessibilityNodes
        #expect(nodes.count < 40)
        #expect(nodes.contains { $0.label == "Dense dashboard" })
        #expect(nodes.contains { $0.label == "\(seriesCount) streams" })
        #expect(nodes.contains { $0.label == "\(seriesCount * 64) data records" })
        #expect(
          nodes.contains {
            $0.label == "Data position" && $0.control?.maximum == Double(seriesCount * 64)
          })
        #expect(!nodes.contains { $0.role == .image })
        #expect(snapshot.semanticSnapshot.focusRegions.isEmpty)
        print(
          "DENSE|\(key)|nodes=\(snapshot.diagnostics.counts.resolvedNodes)|ms=\(durations.sorted()[1])|hashes=\(hashes)"
        )
      }
    }
  }

  // Reviewed for SwiftTUI 0.18.1: ANSI 16 uses the full canonical palette,
  // and ANSI 256 chooses the nearest cube or grayscale entry. The other
  // three profile hashes are unchanged. All five profiles continue to cover
  // glyphs, spaces and color escapes.
  private static let expectedRasterHashes: [String: [UInt64]] = [
    "80x24/1": [
      3_794_535_181_730_491_596, 14_120_472_051_396_231_410, 7_636_968_279_152_145_013,
      3_274_731_090_320_159_268, 6_707_426_177_871_414_973,
    ],
    "80x24/8": [
      8_187_883_608_773_059_987, 13_279_631_796_247_779_380, 355_620_009_916_598_390,
      7_134_656_474_464_175_510, 16_160_053_965_978_429_453,
    ],
    "80x24/32": [
      4_706_802_371_673_219_679, 9_466_899_708_610_300_559, 3_407_913_626_514_353_572,
      3_332_219_292_577_929_280, 13_955_495_513_229_179_143,
    ],
    "160x60/1": [
      3_249_765_465_316_489_054, 9_475_297_198_345_390_290, 4_163_208_963_521_657_631,
      10_300_044_549_377_795_542, 3_033_406_371_846_438_083,
    ],
    "160x60/8": [
      12_069_515_541_134_937_376, 1_426_397_075_838_323_378, 4_177_789_418_011_669_560,
      1_986_591_757_472_889_865, 5_284_179_389_843_088_886,
    ],
    "160x60/32": [
      11_294_401_729_166_200_712, 12_240_321_692_306_271_740, 11_533_325_263_739_306_212,
      8_052_833_242_186_991_650, 13_240_910_799_570_855_655,
    ],
  ]
}
