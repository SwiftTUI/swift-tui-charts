import SwiftTUICharts
import SwiftTUIRuntime
import Testing

// Public render-behavior assertions for every chart family: each test drives
// the public one-shot renderer and asserts on the composed raster surface,
// pinning the user-visible glyph contract (labels, summaries, track glyphs,
// markers) without reaching into framework internals.
@MainActor
@Suite
struct ChartSurfaceRenderTests {
  @Test("Meter and Sparkline render compact metrics displays")
  func metricsDisplaysRenderCompactTracksAndTrendGlyphs() {
    let meterArtifacts = DefaultRenderer().render(
      Meter("Health", value: 7, total: 10, tone: .success, barWidth: 8),
      context: .init(identity: testIdentity("MeterDisplay"))
    )
    let sparklineArtifacts = DefaultRenderer().render(
      Sparkline("Trend", values: [1, 3, 2, 5, 8], tone: .warning),
      context: .init(identity: testIdentity("SparklineDisplay"))
    )

    let meterSurface = meterArtifacts.rasterSurface.lines.joined(separator: "\n")
    let sparklineSurface = sparklineArtifacts.rasterSurface.lines.joined(separator: "\n")
    #expect(meterSurface.contains("Health"))
    #expect(meterSurface.contains("70%"))
    #expect(meterSurface.contains("█"))
    #expect(sparklineSurface.contains("Trend"))
    #expect(sparklineSurface.contains("lo 1 hi 8"))
    #expect(sparklineSurface.contains("▁"))
  }

  @Test("Timeline renders a compact sequence of entries")
  func timelineRendersEntryList() {
    let timelineArtifacts = DefaultRenderer().render(
      Timeline([
        .init("Queued", detail: "Awaiting input", tone: .warning),
        .init("Applied", detail: "Value committed", tone: .success),
      ]),
      context: .init(identity: testIdentity("TimelineDisplay"))
    )

    let timelineSurface = timelineArtifacts.rasterSurface.lines.joined(separator: "\n")
    #expect(timelineSurface.contains("Queued"))
    #expect(timelineSurface.contains("Applied"))
    #expect(timelineSurface.contains("├"))
    #expect(timelineSurface.contains("╰"))
  }

  @Test("Timeline entries without detail collapse to a single row")
  func compactTimelineEntriesDoNotRenderContinuationRows() {
    let artifacts = DefaultRenderer().render(
      Timeline([
        .init("Value 0 | preset 0", tone: .info),
        .init("Mode inspect | tab flow", tone: .warning),
      ]),
      context: .init(identity: testIdentity("CompactTimeline"))
    )

    #expect(artifacts.rasterSurface.lines.count == 2)
    let surface = artifacts.rasterSurface.lines.joined(separator: "\n")
    #expect(surface.contains("Value 0 | preset 0"))
    #expect(surface.contains("Mode inspect | tab flow"))
    #expect(!surface.contains("│"))
  }

  @Test("BarChart renders labeled bars, summaries, and value text")
  func barChartRendersCompactDashboardBars() {
    let artifacts = DefaultRenderer().render(
      BarChart(
        "Run Stats",
        entries: [
          .init("value", value: 4, tone: .success),
          .init("preset", value: 7, tone: .info),
          .init("delta", value: 2, tone: .warning),
        ],
        barWidth: 8,
        labelWidth: 6
      ),
      context: .init(identity: testIdentity("BarChart"))
    )

    let surface = artifacts.rasterSurface.lines.joined(separator: "\n")
    #expect(surface.contains("Run Stats"))
    #expect(surface.contains("max 7"))
    #expect(surface.contains("value"))
    #expect(surface.contains("preset"))
    #expect(surface.contains("delta"))
    #expect(surface.contains("█"))
  }

  @Test("BulletChart renders a filled track with a distinct target marker")
  func bulletChartRendersCurrentVsTargetTrack() {
    let artifacts = DefaultRenderer().render(
      BulletChart(
        "Range",
        value: 4,
        target: 6,
        total: 8,
        tone: .success,
        barWidth: 8
      ),
      context: .init(identity: testIdentity("BulletChart"))
    )

    let surface = artifacts.rasterSurface.lines.joined(separator: "\n")
    #expect(surface.contains("Range"))
    #expect(surface.contains("t 6"))
    #expect(surface.contains("█"))
    #expect(surface.contains("◇") || surface.contains("◆"))
  }

  @Test("ComparisonChart renders current tracks against baseline markers")
  func comparisonChartRendersCompactComparisonRows() {
    let artifacts = DefaultRenderer().render(
      ComparisonChart(
        "Run Compare",
        entries: [
          .init("value", current: 4, baseline: 6, total: 8, tone: .warning),
          .init("delta", current: 2, baseline: 0, total: 8, tone: .success),
        ],
        barWidth: 8,
        labelWidth: 6
      ),
      context: .init(identity: testIdentity("ComparisonChart"))
    )

    let surface = artifacts.rasterSurface.lines.joined(separator: "\n")
    #expect(surface.contains("Run Compare"))
    #expect(surface.contains("max 8"))
    #expect(surface.contains("value"))
    #expect(surface.contains("4/6"))
    #expect(surface.contains("◆") || surface.contains("◇"))
  }

  @Test("ThresholdGauge renders banded tracks with a positioned marker")
  func thresholdGaugeRendersCompactBands() {
    let artifacts = DefaultRenderer().render(
      ThresholdGauge(
        "Preset Sync",
        value: 6,
        total: 10,
        bands: [
          .init(upTo: 3, tone: .warning),
          .init(upTo: 7, tone: .info),
          .init(upTo: 10, tone: .success),
        ],
        barWidth: 8
      ),
      context: .init(identity: testIdentity("ThresholdGauge"))
    )

    let surface = artifacts.rasterSurface.lines.joined(separator: "\n")
    #expect(surface.contains("Preset Sync"))
    #expect(surface.contains("6/10"))
    #expect(surface.contains("◆"))
    #expect(surface.contains("━"))
  }

  @Test("ColumnChart renders stacked rows plus a compact label strip")
  func columnChartRendersCompactVerticalBars() {
    let artifacts = DefaultRenderer().render(
      ColumnChart(
        "Preset Flow",
        entries: [
          .init("-3", value: 3, tone: .warning),
          .init("0", value: 0, tone: .info),
          .init("7", value: 7, tone: .success),
        ],
        chartHeight: 4,
        columnWidth: 2
      ),
      context: .init(identity: testIdentity("ColumnChart"))
    )

    let surface = artifacts.rasterSurface.lines.joined(separator: "\n")
    #expect(surface.contains("Preset Flow"))
    #expect(surface.contains("max 7"))
    #expect(surface.contains("-3"))
    #expect(surface.contains("7"))
    #expect(surface.contains("██"))
  }

  @Test("Legend renders tone-aware markers with compact labels")
  func legendRendersCompactToneKeys() {
    let artifacts = DefaultRenderer().render(
      Legend(
        items: [
          .init("live", tone: .success),
          .init("preset", tone: .info),
          .init("delta", tone: .warning),
        ],
        itemSpacing: 1
      ),
      context: .init(identity: testIdentity("Legend"))
    )

    let surface = artifacts.rasterSurface.lines.joined(separator: "\n")
    #expect(surface.contains("■"))
    #expect(surface.contains("live"))
    #expect(surface.contains("preset"))
    #expect(surface.contains("delta"))
  }

  @Test("StackedBarChart renders a proportional multi-tone track")
  func stackedBarChartRendersCompactSegments() {
    let artifacts = DefaultRenderer().render(
      StackedBarChart(
        "Run Stats",
        entries: [
          .init("live", value: 4, tone: .success),
          .init("preset", value: 2, tone: .info),
          .init("delta", value: 1, tone: .warning),
        ],
        barWidth: 8
      ),
      context: .init(identity: testIdentity("StackedBarChart"))
    )

    let surface = artifacts.rasterSurface.lines.joined(separator: "\n")
    #expect(surface.contains("Run Stats"))
    #expect(surface.contains("sum 7"))
    #expect(surface.contains("█"))
  }

  @Test("HeatStrip renders intensity cells plus a compact label row")
  func heatStripRendersCompactIntensityRow() {
    let artifacts = DefaultRenderer().render(
      HeatStrip(
        "Preset Flow",
        entries: [
          .init("-3", value: 3, tone: .warning),
          .init("0", value: 0, tone: .info),
          .init("7", value: 7, tone: .success),
        ],
        cellWidth: 2
      ),
      context: .init(identity: testIdentity("HeatStrip"))
    )

    let surface = artifacts.rasterSurface.lines.joined(separator: "\n")
    #expect(surface.contains("Preset Flow"))
    #expect(surface.contains("hi 7"))
    #expect(surface.contains("-3"))
    #expect(surface.contains("7"))
    #expect(surface.contains("▒") || surface.contains("▓") || surface.contains("█"))
  }
}
