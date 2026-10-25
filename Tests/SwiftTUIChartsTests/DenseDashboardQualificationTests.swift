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

  // Reviewed for SwiftTUI 0.19.3: stack centring (STUI-1212) puts the odd
  // leftover row below a one-row axis tick that sits beside a value label
  // wrapped onto two rows, so the tick moves from the label's second row to
  // its first. The rasters are otherwise unchanged. ANSI 16 still uses the
  // full canonical palette and ANSI 256 the nearest cube or grayscale entry,
  // and all five profiles cover glyphs, spaces and color escapes.
  private static let expectedRasterHashes: [String: [UInt64]] = [
    "80x24/1": [
      1_311_056_727_450_637_736, 7_820_349_031_056_806_154, 13_722_857_513_170_911_528,
      9_717_755_642_844_392_715, 17_731_546_523_261_781_478,
    ],
    "80x24/8": [
      6_567_253_292_432_372_207, 1_719_555_384_105_437_368, 16_923_428_701_216_959_197,
      15_843_909_629_131_316_643, 16_240_952_637_106_613_868,
    ],
    "80x24/32": [
      9_884_799_713_575_174_189, 8_524_782_225_209_978_869, 18_061_774_299_706_962_357,
      15_465_877_166_225_186_871, 5_759_341_557_011_931_544,
    ],
    "160x60/1": [
      7_480_026_713_287_567_894, 2_061_943_888_413_932_746, 3_252_835_579_093_860_262,
      18_067_518_161_230_110_093, 9_281_077_088_047_937_012,
    ],
    "160x60/8": [
      2_683_575_340_959_396_292, 8_988_399_009_651_754_874, 7_722_477_398_278_299_567,
      9_681_317_737_809_588_478, 11_840_941_567_584_107_325,
    ],
    "160x60/32": [
      4_694_347_965_285_897_356, 9_586_718_885_169_994_816, 7_630_121_581_758_581_377,
      3_642_767_164_279_014_397, 9_386_939_259_935_544_440,
    ],
  ]
}
