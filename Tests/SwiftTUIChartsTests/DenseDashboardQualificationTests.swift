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
        #expect(hashes == Self.originalRasterHashes[key])
        #expect(snapshot.diagnostics.counts.resolvedNodes < size.width * size.height / 4)
        let nodes = snapshot.semanticSnapshot.accessibilityNodes
        #expect(nodes.count == 2)
        #expect(nodes.last?.role == .image)
        #expect(nodes.last?.label == "\(seriesCount) series")
        #expect(
          nodes.last?.rect
            == CellRect(origin: .zero, size: .init(width: size.width, height: size.height - 1)))
        #expect(nodes.last?.hidden == false)
        print(
          "DENSE|\(key)|nodes=\(snapshot.diagnostics.counts.resolvedNodes)|ms=\(durations.sorted()[1])|hashes=\(hashes)"
        )
      }
    }
  }

  // Captured from the cell-view implementation at 2b7a527, before changing
  // production code. Includes glyphs, spaces and color escapes for the five
  // supported terminal profiles in RenderedTextFixtureTerminalConfiguration.
  private static let originalRasterHashes: [String: [UInt64]] = [
    "80x24/1": [
      3_794_535_181_730_491_596, 14_120_472_051_396_231_410, 4_230_350_945_478_060_902,
      15_893_500_352_874_344_475, 13_961_700_499_961_138_818,
    ],
    "80x24/8": [
      8_187_883_608_773_059_987, 13_279_631_796_247_779_380, 1_548_013_264_981_791_965,
      14_851_768_244_255_769_477, 8_797_668_825_317_745_366,
    ],
    "80x24/32": [
      4_706_802_371_673_219_679, 9_466_899_708_610_300_559, 13_367_411_838_984_546_596,
      13_964_394_672_864_949_748, 8_970_455_741_263_413_844,
    ],
    "160x60/1": [
      3_249_765_465_316_489_054, 9_475_297_198_345_390_290, 3_665_400_086_816_159_084,
      18_382_274_619_432_652_785, 10_109_397_926_600_197_228,
    ],
    "160x60/8": [
      12_069_515_541_134_937_376, 1_426_397_075_838_323_378, 9_936_811_729_144_660_497,
      17_283_440_971_046_684_401, 13_500_263_367_939_791_213,
    ],
    "160x60/32": [
      11_294_401_729_166_200_712, 12_240_321_692_306_271_740, 6_183_816_733_697_862_482,
      5_086_557_663_598_899_479, 3_082_454_240_124_604_630,
    ],
  ]
}
